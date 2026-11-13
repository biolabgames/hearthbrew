"""Trace hand contours from the user's real sampled frames; no image synthesis.

Reads pixels only. Outputs coordinates and provenance, never redraws image files.
The Godot importer separately crops/packs unchanged source pixels for rendering.
"""
from pathlib import Path
import hashlib, json, math
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT.parent / 'work'
KEYS = {
 'left': [(0,165,132,147,160,185,126),(8,168,130,146,160,188,126),(12,185,105,159,133,205,100),(18,185,139,163,162,204,130),(23,185,95,163,120,206,65),(28,189,80,164,112,214,53),(36,208,55,178,91,246,48),(42,192,85,170,115,219,80),(47,172,105,150,135,188,89),(55,175,112,151,141,192,95),(60,159,125,139,153,180,125),(71,160,146,138,175,180,136)],
 'right': [(0,375,186,382,211,351,176),(8,370,187,382,217,350,174),(12,393,163,400,195,377,151),(15,410,118,425,150,393,108),(18,383,66,408,99,363,63),(22,343,51,373,77,320,59),(24,317,68,347,94,283,84),(30,296,63,325,87,269,75),(36,329,72,358,100,301,85),(42,294,68,326,97,264,83),(48,321,67,354,97,291,83),(54,300,76,332,103,270,89),(60,316,55,349,85,285,66),(64,336,101,363,132,309,108),(68,371,153,392,183,347,151),(72,379,184,392,213,353,175),(83,377,191,392,222,353,179)]
}

def landmarks(side, index):
    keys = KEYS[side]
    for a,b in zip(keys,keys[1:]):
        if a[0] <= index <= b[0]:
            t=(index-a[0])/(b[0]-a[0])
            return np.array(a[1:])*(1-t)+np.array(b[1:])*t
    return np.array(keys[-1][1:],dtype=float)

def component(mask, seed):
    ys,xs=np.where(mask)
    if not len(xs): raise ValueError('No hand pixels near source landmark')
    i=np.argmin((xs-seed[0])**2+(ys-seed[1])**2)
    pending=[(int(xs[i]),int(ys[i]))]; seen=set(pending)
    while pending:
        x,y=pending.pop()
        for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
            nx,ny=x+dx,y+dy
            if 0<=nx<mask.shape[1] and 0<=ny<mask.shape[0] and mask[ny,nx] and (nx,ny) not in seen:
                seen.add((nx,ny)); pending.append((nx,ny))
    return np.array(list(seen),dtype=float)

def trace(side, directory):
    records=[]
    for index,path in enumerate(sorted(directory.glob('frame-*.png'))):
        rgb=np.asarray(Image.open(path).convert('RGB')).astype(float)
        palm,wrist,grip=landmarks(side,index).reshape(3,2)
        yy,xx=np.mgrid[:rgb.shape[0],:rgb.shape[1]]
        axis=(palm-wrist); axis/=np.linalg.norm(axis)
        mask=(rgb[:,:,0]-rgb[:,:,1]>5)&(rgb[:,:,0]-rgb[:,:,2]>12)
        mask &= ((xx-palm[0])**2+(yy-palm[1])**2 < 65**2)
        # Keep nearby warm-coloured mugs/trays out of the hand component.
        mask &= (xx >= palm[0]-(36 if side=='left' else 48)) & (xx <= palm[0]+(48 if side=='left' else 56))
        mask &= ((xx-wrist[0])*axis[0]+(yy-wrist[1])*axis[1] >= -1)
        # Fill small classification holes, retaining the wrist clipping plane.
        padded=np.pad(mask,1)
        expanded=np.logical_or.reduce([padded[1+dy:1+dy+mask.shape[0],1+dx:1+dx+mask.shape[1]] for dy in [-1,0,1] for dx in [-1,0,1]])
        padded=np.pad(expanded,1)
        closed=np.logical_and.reduce([padded[1+dy:1+dy+mask.shape[0],1+dx:1+dx+mask.shape[1]] for dy in [-1,0,1] for dx in [-1,0,1]])
        pixels=component(closed,palm)
        center=np.median(pixels,axis=0)
        angles=np.arctan2(pixels[:,1]-center[1],pixels[:,0]-center[0])
        radii=np.linalg.norm(pixels-center,axis=1)
        contour=[]
        for angle in np.linspace(-math.pi,math.pi,64,endpoint=False):
            delta=np.abs(np.angle(np.exp(1j*(angles-angle))))
            near=delta < math.pi/48
            radius=float(np.quantile(radii[near],0.97)) if near.any() else 1.0
            contour.append((center+np.array([math.cos(angle),math.sin(angle)])*radius).tolist())
        crop=[max(0,min(352,int(palm[0])-64)),max(0,min(142,int(palm[1])-64)),128,128]
        records.append({'index':index,'time':index/12,'source_frame':path.name,'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'crop':crop,'palm':palm.tolist(),'wrist':wrist.tolist(),'grip':grip.tolist(),'contour':contour,'raw_contour':contour,'skin_pixels':len(pixels),
            'skin_luma':float(np.median(rgb[pixels[:,1].astype(int),pixels[:,0].astype(int)].mean(axis=1))/255)})
    # Smooth coordinates in reference space, preserving endpoints and ordering.
    for field in ['contour','grip','wrist','palm']:
        raw=np.array([r[field] for r in records])
        for i,record in enumerate(records):
            ids=[max(0,min(len(records)-1,i+d)) for d in [-2,-1,0,1,2]]
            record[field]=(sum(raw[k]*w for k,w in zip(ids,[1,2,3,2,1]))/9).tolist()
    return records

output={'version':1,'fps':12,'method':'Original user video pixels with source-derived skin contours; 5-frame weighted stabilization. No generated hand images or mirroring.', 'clips':{}}
for side,directory in [('left',WORK/'rotoscope/native-frames'),('right',WORK/'rotoscope-010936/frames')]:
    frames=trace(side,directory)
    widths=[max(p[0] for p in r['contour'])-min(p[0] for p in r['contour']) for r in frames]
    output['clips'][side]={'video':'20261106_010812.mp4' if side=='left' else '20261106_010936.mp4','frames':frames,'scale':round(94/float(np.median(widths)),5)}
    print(side,len(frames),'hand pixel range',min(r['skin_pixels'] for r in frames),max(r['skin_pixels'] for r in frames),'median width',float(np.median(widths)))
destination=ROOT/'resources/hands/user_video_traces.json'
destination.write_text(json.dumps(output,separators=(',',':')))
print('Saved',destination)
