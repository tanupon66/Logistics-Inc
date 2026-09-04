from pathlib import Path
import random
random.seed(1873)
P=Path('assets'); P.mkdir(exist_ok=True)

def r(x,y,w,h,c,s='#1b2328',sw=1): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" stroke="{s}" stroke-width="{sw}"/>'
def l(x1,y1,x2,y2,c,sw=1,d=''): return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{c}" stroke-width="{sw}"'+(f' stroke-dasharray="{d}"' if d else '')+'/>'
def p(a,c,s='#1b2328',sw=1): return '<polygon points="'+' '.join(f'{x},{y}' for x,y in a)+f'" fill="{c}" stroke="{s}" stroke-width="{sw}"/>'
def tx(x,y,t,n=12,c='#f4e2ab'): return f'<text x="{x}" y="{y}" font-family="sans-serif" font-size="{n}" fill="{c}">{t}</text>'

def building(x,y,w,h,c):
    d=14
    out=p([(x,y-h),(x+w,y-h),(x+w+d,y-h-8),(x+d,y-h-8)],'#6f6859')+r(x,y-h,w,h,c)+p([(x+w,y-h),(x+w+d,y-h-8),(x+w+d,y-8),(x+w,y)],'#3d3b38')
    for yy in range(y-h+8,y-5,16):
        for xx in range(x+7,x+w-5,15): out+=r(xx,yy,5,7,'#d8b45b','none',0)
    return out

def crane(x,y,k=1):
    return l(x,y,x,y-70*k,'#d9a728',5*k)+l(x,y-70*k,x+55*k,y-70*k,'#d9a728',4*k)+l(x,y-58*k,x+43*k,y-25*k,'#d9a728',2*k)+l(x+44*k,y-70*k,x+44*k,y-22*k,'#252a2c',1)+r(x+39*k,y-22*k,10*k,7*k,'#c35d2d')

def ship(x,y,k=1,c='#a33a2e'):
    q=p([(x-60*k,y),(x+55*k,y),(x+70*k,y+10*k),(x+42*k,y+20*k),(x-52*k,y+20*k)],c)+r(x-18*k,y-18*k,52*k,18*k,'#eee6d2')
    q+=r(x+5*k,y-31*k,24*k,13*k,'#f6f0de')
    for z in [-12,5,22]: q+=r(x+z*k,y-43*k,9*k,25*k,'#252a2c')
    return q

S=['<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720">','<defs><linearGradient id="w" x2="0" y2="1"><stop stop-color="#1b6687"/><stop offset="1" stop-color="#0b3b56"/></linearGradient></defs>',r(0,0,1280,720,'#789275','none',0),r(0,380,1280,340,'url(#w)','none',0)]
S.append(p([(0,0),(1280,0),(1280,455),(1100,425),(930,450),(770,420),(610,450),(420,410),(230,435),(0,395)],'#687d5b','none',0))
for y in [135,175,215]: S+= [l(-80,y,1200,y-80,'#3f4443',14),l(-80,y,1200,y-80,'#b4a98f',2)]
for x,y,w,h in [(0,360,390,95),(300,390,330,105),(590,405,310,120),(850,420,330,125)]: S.append(p([(x,y),(x+w,y-20),(x+w,y+h-20),(x,y+h)],'#777267'))
colors=['#725342','#67554d','#7d5a43','#5d5e60','#716b59']
for i in range(62):
    x=random.randint(20,1100); y=random.randint(110,340)
    if 430<x<880 and 245<y<360: continue
    S.append(building(x,y,random.randint(28,66),random.randint(25,80),random.choice(colors)))
for x,y,w in [(430,335,145),(600,345,190),(800,355,140)]: S.append(building(x,y,w,48,'#536776'))
S.append(building(700,225,135,72,'#705747'))
for x in [730,765,800]: S.append(r(x,65,18,125,'#5b3b2f')); S.append(r(x-3,60,24,8,'#302725'))
for x in [975,1025,1075,1125]: S.append(r(x,245,44,52,'#aaa9a0')); S.append(f'<ellipse cx="{x+22}" cy="245" rx="22" ry="8" fill="#ceccc1"/>')
for x,y,k in [(170,435,1),(260,445,.9),(390,470,1.1),(510,480,1),(655,490,1.1),(740,495,.9),(900,510,1.15),(1020,520,1)]: S.append(crane(x,y,k))
for i in range(19): S.append(r(80+i*47,205-i*3,36,9,random.choice(['#85332f','#31577a','#6d5631'])))
for i in range(36):
    x=20+i*33; y=int(270-(x*.075)%90); S.append(r(x,y,13,6,random.choice(['#b33f34','#d7c7a3','#367494','#d58a2b'])))
for a in [(160,515,1.05),(520,585,1.2),(860,625,1),(1120,560,.8),(330,665,.62)]: S.append(ship(*a))
for x,y,t in [(515,315,'WAREHOUSE'),(930,390,'SHIPYARD'),(250,345,'DRY DOCK'),(850,245,'RAIL TERMINAL')]: S.append(r(x-58,y-18,125,24,'#071923','#b89545')); S.append(tx(x-48,y,t,11))
S.append('</svg>'); (P/'port_backdrop_v04.svg').write_text(''.join(S))

M=['<svg xmlns="http://www.w3.org/2000/svg" width="900" height="520">',r(0,0,900,520,'#0d4268','none',0),tx(350,34,'WORLD TRADE ROUTES',22)]
for pts in [[(80,95),(160,60),(250,80),(300,135),(250,175),(110,140)],[(220,190),(285,205),(300,280),(255,350),(205,250)],[(390,85),(500,60),(620,85),(700,130),(625,175),(525,160),(450,210)],[(470,215),(550,210),(590,270),(555,350),(500,365)],[(690,300),(765,290),(820,335),(775,375)]]: M.append(p(pts,'#738451','#9a9b70'))
routes=[((150,140),(430,120)),((150,140),(520,250)),((430,120),(740,320)),((520,250),(740,320)),((430,120),(775,155))]
for a,b in routes:M.append(l(*a,*b,'#efe7c7',2,'8 6'))
for x,y,n in [(150,140,'London'),(90,170,'New York'),(430,120,'Hamburg'),(520,250,'Cape Town'),(740,320,'Singapore'),(775,155,'Shanghai')]: M.append(f'<circle cx="{x}" cy="{y}" r="6" fill="#f1b840"/>'); M.append(tx(x+10,y-8,n,11))
M.append('</svg>'); (P/'world_map_v04.svg').write_text(''.join(M))
