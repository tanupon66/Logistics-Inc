from pathlib import Path
import random

P = Path('assets')
P.mkdir(exist_ok=True)
random.seed(1750)


def r(x,y,w,h,c,s='none',sw=0,rx=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{c}" stroke="{s}" stroke-width="{sw}"/>'

def l(x1,y1,x2,y2,c,sw=1,d=''):
    dash = f' stroke-dasharray="{d}"' if d else ''
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{c}" stroke-width="{sw}"{dash}/>'

def p(points,c,s='none',sw=0):
    pts=' '.join(f'{x},{y}' for x,y in points)
    return f'<polygon points="{pts}" fill="{c}" stroke="{s}" stroke-width="{sw}"/>'

def c(cx,cy,rr,fill,opacity=1):
    return f'<circle cx="{cx}" cy="{cy}" r="{rr}" fill="{fill}" opacity="{opacity}"/>'

def tx(x,y,t,n=12,col='#f2ddb0',weight='normal'):
    return f'<text x="{x}" y="{y}" font-family="serif" font-size="{n}" font-weight="{weight}" fill="{col}">{t}</text>'


def iso_house(x,y,w=52,h=48,wall='#78563f',roof='#3e4344'):
    d=max(8,int(w*0.18))
    out=[]
    out.append(p([(x,y-h),(x+w,y-h),(x+w+d,y-h-d//2),(x+d,y-h-d//2)], roof, '#24282a', 1))
    out.append(r(x,y-h,w,h,wall,'#2a2927',1))
    out.append(p([(x+w,y-h),(x+w+d,y-h-d//2),(x+w+d,y-d//2),(x+w,y)], '#4c3c34','#292725',1))
    for yy in range(y-h+10,y-8,16):
        for xx in range(x+8,x+w-6,16):
            out.append(r(xx,yy,5,7,'#d5b168','#3b3025',.5))
    out.append(r(x+w//2-5,y-18,10,18,'#4e382a','#2a211b',1))
    return ''.join(out)


def warehouse(x,y,w=120,h=64,label='WAREHOUSE'):
    out=[]
    out.append(iso_house(x,y,w,h,'#80694e','#4b5050'))
    out.append(r(x+14,y-32,22,32,'#4b3a2a','#27221b',1))
    out.append(r(x+w-36,y-32,22,32,'#4b3a2a','#27221b',1))
    out.append(tx(x+14,y-h+25,label,10,'#e6d6ae','bold'))
    return ''.join(out)


def wooden_crane(x,y,k=1.0):
    out=[]
    out.append(l(x,y,x,y-72*k,'#6b4829',5*k))
    out.append(l(x,y-65*k,x+48*k,y-87*k,'#7c542d',5*k))
    out.append(l(x+48*k,y-87*k,x+54*k,y-23*k,'#2e2922',1.5*k))
    out.append(l(x,y-30*k,x+40*k,y-78*k,'#4b3424',3*k))
    out.append(r(x+49*k,y-22*k,10*k,8*k,'#9a6b36','#31291f',1))
    return ''.join(out)


def sail_ship(x,y,k=1.0,hull='#4b2f22',sails='#eee1bd'):
    out=[]
    out.append(p([(x-58*k,y),(x+50*k,y),(x+62*k,y+8*k),(x+35*k,y+18*k),(x-44*k,y+18*k)],hull,'#211c18',1.5))
    out.append(l(x-15*k,y,x-15*k,y-82*k,'#34251b',3*k))
    out.append(l(x+20*k,y,x+20*k,y-70*k,'#34251b',3*k))
    out.append(p([(x-14*k,y-77*k),(x-49*k,y-58*k),(x-16*k,y-48*k)],sails,'#76684f',1))
    out.append(p([(x-13*k,y-73*k),(x+13*k,y-57*k),(x-13*k,y-48*k)],'#f3e8c8','#76684f',1))
    out.append(p([(x+21*k,y-65*k),(x+48*k,y-48*k),(x+21*k,y-41*k)],'#eadab5','#76684f',1))
    out.append(l(x-48*k,y+8*k,x+63*k,y+8*k,'#bd8b47',1.5*k))
    return ''.join(out)


def cart(x,y,k=1.0):
    return ''.join([
        r(x,y,24*k,10*k,'#6a4327','#251f19',1),
        c(x+5*k,y+12*k,4*k,'#29241f'), c(x+20*k,y+12*k,4*k,'#29241f'),
        l(x+24*k,y+5*k,x+37*k,y+2*k,'#59422c',2*k),
        p([(x+37*k,y-3*k),(x+48*k,y),(x+38*k,y+5*k)],'#795232','#30251c',1)
    ])


def shipyard_frame(x,y,w=190,h=110):
    out=[]
    out.append(p([(x,y),(x+w,y-22),(x+w,y+h-22),(x,y+h)],'#62584b','#262522',1))
    for xx in range(x+6,x+w-5,18):
        out.append(l(xx,y+5,xx,y+h-8,'#694823',3))
        out.append(l(xx,y+5,xx+50,y+h-10,'#4a341f',1))
    out.append(sail_ship(x+w*.48,y+h*.53,.72,'#6a3c25','#cbbf9f'))
    return ''.join(out)


def port_svg():
    S=['<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">']
    S.append('<defs><linearGradient id="sea" x2="0" y2="1"><stop stop-color="#2f7890"/><stop offset="1" stop-color="#0c435a"/></linearGradient><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#b9d3ca"/><stop offset="1" stop-color="#8da592"/></linearGradient></defs>')
    S.append(r(0,0,1280,720,'url(#sky)'))
    S.append(r(0,355,1280,365,'url(#sea)'))
    S.append(p([(0,0),(1280,0),(1280,395),(1130,385),(1000,410),(840,395),(690,430),(530,406),(370,430),(205,405),(0,425)],'#7e8767','#42503f',2))
    S.append(p([(0,350),(1280,318),(1280,430),(1100,424),(940,455),(770,440),(620,472),(470,445),(305,468),(145,440),(0,462)],'#7a7061','#3b3935',2))
    for y in [100,145,195,248,303]:
        S.append(l(-100,y,1210,y-55,'#555854',18))
        S.append(l(-100,y,1210,y-55,'#c0b79f',2))
    for x in [220,460,690,925,1120]:
        S.append(l(x,40,x+95,344,'#535650',14))
        S.append(l(x,40,x+95,344,'#b9b096',2))
    palette=['#74503d','#865e45','#665b50','#8a674c','#5e6460','#79624b']
    for _ in range(88):
        x=random.randint(10,1180); y=random.randint(70,334)
        if 780<x<1120 and 225<y<360: continue
        S.append(iso_house(x,y,random.randint(28,58),random.randint(30,74),random.choice(palette),random.choice(['#3e4445','#4b423b','#374044'])))
    S += [r(615,68,52,155,'#777262','#3a3932',2), p([(606,68),(676,68),(641,18)],'#3f4445','#2c3031',2), c(641,94,15,'#d9c888'), c(641,94,10,'#eee1ad'), l(641,94,641,84,'#3b3427',2), l(641,94,649,98,'#3b3427',2)]
    S.append(warehouse(385,335,150,70,'EASTERN TRADING CO.'))
    S.append(warehouse(955,347,145,72,'WAREHOUSE No.3'))
    S.append(warehouse(750,330,170,76,'ROYAL SHIPYARD'))
    S.append(shipyard_frame(680,390,235,110))
    S.append(shipyard_frame(920,405,190,95))
    for x,y,w,h in [(20,400,260,75),(250,420,250,82),(495,440,230,85),(720,455,240,90),(955,445,285,90)]:
        S.append(p([(x,y),(x+w,y-20),(x+w,y+h-20),(x,y+h)],'#7a7164','#35312c',2))
        for xx in range(x+8,x+w,24): S.append(l(xx,y+h-4,xx+5,y+h+20,'#493624',4))
    for x,y,w in [(90,490,130),(340,505,110),(575,530,140),(1010,540,150)]:
        S.append(r(x,y,w,18,'#694a2d','#2b241d',2))
        for xx in range(x+6,x+w,16): S.append(l(xx,y+16,xx,y+42,'#4f3925',3))
    for x,y,k in [(135,430,1),(300,450,.85),(455,460,.95),(605,478,1.1),(835,483,.95),(1080,474,1.0)]: S.append(wooden_crane(x,y,k))
    for _ in range(40):
        x=random.randint(40,1160); y=random.randint(275,420)
        S.append(cart(x,y,random.choice([.45,.55,.65])))
    for _ in range(55):
        x=random.randint(60,1160); y=random.randint(365,470)
        S.append(r(x,y,random.randint(7,15),random.randint(5,10),random.choice(['#8b5a2b','#6f4424','#9a7a42','#5b4028']),'#2e241d',.6))
    for a in [(115,540,.9),(345,620,.72),(610,565,.88),(785,645,.6),(1040,585,.8),(1190,640,.55)]: S.append(sail_ship(*a))
    S += [p([(1165,610),(1200,610),(1193,535),(1173,535)],'#d9d0bb','#3c3932',2),r(1172,520,22,18,'#b14537','#342823',1),p([(1167,520),(1199,520),(1183,506)],'#30383a','#25292a',1)]
    for _ in range(120):
        y=random.randint(380,705); x=random.randint(0,1260); ln=random.randint(8,28)
        S.append(l(x,y,x+ln,y+random.randint(-3,3),'#8bc4cc',random.choice([1,1,2])))
    S.append(r(18,18,210,34,'#17282a','#b48a47',2,3)); S.append(tx(31,42,'LIVERPOOL • 1750',18,'#f1d18a','bold'))
    S.append('</svg>')
    return ''.join(S)


def world_map_svg():
    M=['<svg xmlns="http://www.w3.org/2000/svg" width="900" height="520">',r(0,0,900,520,'#0d4268')]
    for pts in [[(80,95),(160,60),(250,80),(300,135),(250,175),(110,140)],[(220,190),(285,205),(300,280),(255,350),(205,250)],[(390,85),(500,60),(620,85),(700,130),(625,175),(525,160),(450,210)],[(470,215),(550,210),(590,270),(555,350),(500,365)],[(690,300),(765,290),(820,335),(775,375)]]: M.append(p(pts,'#738451','#9a9b70',1))
    routes=[((150,140),(430,120)),((150,140),(520,250)),((430,120),(740,320)),((520,250),(740,320)),((430,120),(775,155))]
    for a,b in routes:M.append(l(*a,*b,'#efe7c7',2,'8 6'))
    for x,y,n in [(150,140,'London'),(90,170,'New York'),(430,120,'Hamburg'),(520,250,'Cape Town'),(740,320,'Singapore'),(775,155,'Shanghai')]: M.append(c(x,y,6,'#f1b840')); M.append(tx(x+10,y-8,n,11))
    M.append('</svg>')
    return ''.join(M)

(P/'port_backdrop_v05.svg').write_text(port_svg())
(P/'world_map_v05.svg').write_text(world_map_svg())
(P/'port_backdrop_v04.svg').write_text(port_svg())
(P/'world_map_v04.svg').write_text(world_map_svg())