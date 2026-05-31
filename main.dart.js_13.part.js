((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,B,G,I,F,C={
bnn(){return new C.rp(null)},
o0:function o0(d,e){this.a=d
this.b=e},
rp:function rp(d){this.a=d},
Or:function Or(d,e,f,g,h){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.y=_.x=_.w=!1
_.z=h
_.c=_.a=null},
aPf:function aPf(){},
aPj:function aPj(){},
aPi:function aPi(d){this.a=d},
aPA:function aPA(d){this.a=d},
aPr:function aPr(){},
aPz:function aPz(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
aPs:function aPs(d){this.a=d},
aPq:function aPq(d){this.a=d},
aPt:function aPt(d){this.a=d},
aPp:function aPp(d){this.a=d},
aPu:function aPu(d){this.a=d},
aPo:function aPo(d){this.a=d},
aPv:function aPv(d){this.a=d},
aPn:function aPn(d){this.a=d},
aPw:function aPw(d){this.a=d},
aPm:function aPm(d){this.a=d},
aPx:function aPx(d,e){this.a=d
this.b=e},
aPl:function aPl(d){this.a=d},
aPy:function aPy(d,e){this.a=d
this.b=e},
aPk:function aPk(){},
aPe:function aPe(d){this.a=d},
aPd:function aPd(d,e){this.a=d
this.b=e},
aPg:function aPg(d){this.a=d},
aPh:function aPh(d){this.a=d}},D,E,K,H,L,M
A=c[0]
B=c[2]
G=c[12]
I=c[6]
F=c[7]
C=a.updateHolder(c[4],C)
D=c[16]
E=c[10]
K=c[9]
H=c[17]
L=c[14]
M=c[18]
C.o0.prototype={
H(){return"_ManagerAuthMode."+this.b}}
C.rp.prototype={
a7(){var x=$.ah()
return new C.Or(new A.c7(B.b2,x),new A.c7(B.b2,x),new A.c7(B.b2,x),new A.c7(B.b2,x),D.fp)}}
C.Or.prototype={
azN(){var x=this,w="Password and confirm password must match.",v="Please enter a valid 6-digit OTP.",u=B.n.W(B.n.W(x.d.a.a)),t=A.cR("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$",!1)
if(!t.b.test(u.toLowerCase()))return"Please enter a valid registered email address."
u=x.z
if(u===D.fp)if(x.e.a.a.length===0)return"Please enter your password."
if(u===D.iy){u=x.c
u.toString
if(!E.bW(u,!1,y.n).x){u=x.e.a.a
if(u.length===0||x.f.a.a.length===0)return"Please create and confirm your password."
if(u!==x.f.a.a)return w}else if(B.n.W(x.r.a.a).length!==6)return v}if(x.z===D.ky){u=x.c
u.toString
if(E.bW(u,!1,y.n).y){if(B.n.W(x.r.a.a).length!==6)return v
u=x.e.a.a
if(u.length===0||x.f.a.a.length===0)return"Please enter and confirm your new password."
if(u!==x.f.a.a)return w}}return null},
l(){var x=this,w=x.d,v=w.L$=$.ah()
w.G$=0
w=x.e
w.L$=v
w.G$=0
w=x.f
w.L$=v
w.G$=0
w=x.r
w.L$=v
w.G$=0
x.ap()},
xs(){var x=0,w=A.z(y.q),v,u=this,t,s,r
var $async$xs=A.v(function(d,e){if(d===1)return A.w(e,w)
for(;;)switch(x){case 0:r=u.c
r.toString
t=y.n
x=3
return A.t(E.bW(r,!1,t).zw(B.n.W(u.d.a.a),u.e.a.a),$async$xs)
case 3:s=e
r=u.c
if(r==null){x=1
break}x=s?4:5
break
case 4:x=6
return A.t(A.af0("web_mall_manager_dashboard",""),$async$xs)
case 6:r=u.c
if(r==null){x=1
break}A.aT(r,!1).lc(A.cr(new C.aPf(),null,y.b))
x=1
break
case 5:r=E.bW(r,!1,t).ax
if(r==null)r="Unable to sign in."
u.c.N(y.v).f.bf(A.di(null,null,null,null,null,B.K,null,A.u(r,null,null,null,null,null,null,null),null,B.ak,null,null,null,null,null,null,null,null,null,null))
case 1:return A.x(v,w)}})
return A.y($async$xs,w)},
Di(){var x=0,w=A.z(y.q),v,u=this,t,s,r,q
var $async$Di=A.v(function(d,e){if(d===1)return A.w(e,w)
for(;;)switch(x){case 0:q=u.c
q.toString
t=E.bW(q,!1,y.n)
q=B.n.W(u.d.a.a)
s=u.e.a.a
x=3
return A.t(t.HR(u.f.a.a,q,s),$async$Di)
case 3:r=e
q=u.c
if(q==null){x=1
break}s=t.ax
if(s==null)s=r?"OTP sent to your email.":"Unable to send OTP."
q.N(y.v).f.bf(A.di(null,null,null,null,null,B.K,null,A.u(s,null,null,null,null,null,null,null),null,B.ak,null,null,null,null,null,null,null,null,null,null))
case 1:return A.x(v,w)}})
return A.y($async$Di,w)},
xV(){var x=0,w=A.z(y.q),v,u=this,t,s,r,q
var $async$xV=A.v(function(d,e){if(d===1)return A.w(e,w)
for(;;)switch(x){case 0:q=u.c
q.toString
t=E.bW(q,!1,y.n)
q=t.Q
x=3
return A.t(t.As(B.n.W(q==null?u.d.a.a:q),B.n.W(u.r.a.a)),$async$xV)
case 3:s=e
q=u.c
if(q==null){x=1
break}x=s?4:5
break
case 4:x=6
return A.t(A.af0("web_mall_manager_dashboard",""),$async$xV)
case 6:q=u.c
if(q==null){x=1
break}A.aT(q,!1).lc(A.cr(new C.aPj(),null,y.b))
x=1
break
case 5:r=t.ax
if(r==null)r="OTP verification failed."
q.N(y.v).f.bf(A.di(null,null,null,null,null,B.K,null,A.u(r,null,null,null,null,null,null,null),null,B.ak,null,null,null,null,null,null,null,null,null,null))
case 1:return A.x(v,w)}})
return A.y($async$xV,w)},
Dh(){var x=0,w=A.z(y.q),v,u=this,t,s,r,q
var $async$Dh=A.v(function(d,e){if(d===1)return A.w(e,w)
for(;;)switch(x){case 0:q=u.c
q.toString
t=E.bW(q,!1,y.n)
x=3
return A.t(t.HQ(B.n.W(u.d.a.a)),$async$Dh)
case 3:s=e
q=u.c
if(q==null){x=1
break}r=t.ax
if(r==null)r=s?"Password reset OTP sent to your email.":"Unable to send OTP."
q.N(y.v).f.bf(A.di(null,null,null,null,null,B.K,null,A.u(r,null,null,null,null,null,null,null),null,B.ak,null,null,null,null,null,null,null,null,null,null))
case 1:return A.x(v,w)}})
return A.y($async$Dh,w)},
Dk(){var x=0,w=A.z(y.q),v,u=this,t,s,r,q,p,o,n,m
var $async$Dk=A.v(function(d,e){if(d===1)return A.w(e,w)
for(;;)switch(x){case 0:m=u.c
m.toString
t=E.bW(m,!1,y.n)
m=t.Q
m=B.n.W(m==null?u.d.a.a:m)
s=u.r
r=B.n.W(s.a.a)
q=u.e
p=q.a.a
o=u.f
x=3
return A.t(t.HU(o.a.a,m,p,r),$async$Dk)
case 3:n=e
m=u.c
if(m==null){x=1
break}if(n){m.N(y.v).f.bf(A.di(null,null,null,null,null,B.K,null,A.u("Password reset successful. Please sign in.",null,null,null,null,null,null,null),null,B.ak,null,null,null,null,null,null,null,null,null,null))
s.eg(0,B.cK)
q.eg(0,B.cK)
o.eg(0,B.cK)
u.I(new C.aPi(u))
x=1
break}s=t.ax
if(s==null)s="Unable to reset password."
m.N(y.v).f.bf(A.di(null,null,null,null,null,B.K,null,A.u(s,null,null,null,null,null,null,null),null,B.ak,null,null,null,null,null,null,null,null,null,null))
case 1:return A.x(v,w)}})
return A.y($async$Dk,w)},
A(d){var x=null,w=E.bW(d,!0,y.n),v=w.x,u=w.y
return A.awn(!1,A.hn(K.jK(x,x,x,x,0,x,x,x,D.b3p),x,A.m4(new C.aPz(this,v,u,w)),x,x,x),new C.aPA(d),y.E)},
ahU(){var x=y.F
return F.bbf(new C.aPe(this),D.aOV,A.cE([this.z],x),null,x)},
wK(d,e,f,g){var x=null,w=A.an(8)
return A.cS(x,B.aB,!1,x,!0,B.K,x,A.cY(),d,x,x,x,x,x,2,A.fr(x,new E.e8(4,w,B.cS),x,x,x,x,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,e,!0,!0,!1,x,G.yW,x,x,x,x,x,x,A.ef(x,x,x,A.cV(f?G.yP:G.yQ,x,x,x),x,x,g,x,x,x,x),x,x,x,x,x),B.ab,!0,x,!0,x,!1,x,B.aA,x,x,x,x,x,x,x,x,1,x,x,f,"\u2022",x,x,x,x,x,!1,x,x,!1,x,!0,x,B.at,x,x,x,x,x,x,x,x,x,x,x,x,!0,B.ai,x,B.au,x,x,x,x)},
Vg(){var x=null
return A.cS(x,B.aB,!1,x,!0,B.K,x,A.cY(),this.r,x,x,x,x,x,2,A.fr(x,new E.e8(4,A.an(8),B.cS),x,x,x,x,"",x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,"Enter 6-digit code",x,x,x,x,x,x,x,x,"OTP",!0,!0,!1,x,D.a14,x,x,x,x,x,x,x,x,x,x,x,x),B.ab,!0,x,!0,x,!1,x,B.aA,x,x,x,x,B.il,x,6,x,1,x,x,!1,"\u2022",x,x,x,x,x,!1,x,x,!1,x,!0,x,B.at,x,x,x,x,x,x,x,x,x,x,x,x,!0,B.ai,x,B.au,x,x,x,x)},
Ve(d,e,f){var x=null,w=A.an(12),v=y.u,u=A.b([D.b4a,B.cx,A.u(d,x,x,x,D.b16,x,x,x)],v)
if(e!=null)B.l.R(u,A.b([B.b5,A.u("Code valid until "+e.aM5().j(0),x,x,x,D.PV,x,x,x)],v))
if(f!=null)B.l.R(u,A.b([B.c9,A.u("Development OTP: "+f,x,x,x,D.b2H,x,x,x)],v))
return A.ay(x,A.a7(u,B.Q,B.x,B.y),B.H,x,x,new A.ax(H.cr,x,x,w,x,x,B.T),x,x,x,x,H.cV,x,x,x)},
ay5(d,e){var x
if(d)return"Enter the OTP sent to your linked manager email to finish account setup."
if(e)return"Verify your email with OTP and create a new password for this manager account."
switch(this.z.a){case 0:x="Sign in with the email linked to your manager account."
break
case 1:x="Use your linked manager email and create a password for first-time access."
break
case 2:x="Enter your linked manager email to reset your password with OTP."
break
default:x=null}return x},
av9(d,e){var x=this.z
if(x===D.fp)return"Sign In"
if(x===D.iy)return d?"Verify OTP":"Create Account"
return e?"Reset Password":"Send OTP"},
oT(){var x=0,w=A.z(y.q),v,u=2,t=[],s=[],r=this,q,p,o,n,m,l
var $async$oT=A.v(function(d,e){if(d===1){t.push(e)
x=u}for(;;)switch(x){case 0:l=r.azN()
if(l!=null){r.c.N(y.v).f.bf(A.di(null,null,null,null,null,B.K,null,A.u(l,null,null,null,null,null,null,null),null,B.ak,null,null,null,null,null,null,null,null,null,null))
x=1
break}r.I(new C.aPg(r))
u=3
o=r.z
x=o===D.fp?6:8
break
case 6:x=9
return A.t(r.xs(),$async$oT)
case 9:x=7
break
case 8:n=y.n
m=r.c
x=o===D.iy?10:12
break
case 10:m.toString
q=E.bW(m,!1,n)
x=q.x?13:15
break
case 13:x=16
return A.t(r.xV(),$async$oT)
case 16:x=14
break
case 15:x=17
return A.t(r.Di(),$async$oT)
case 17:case 14:x=11
break
case 12:m.toString
p=E.bW(m,!1,n)
x=p.y?18:20
break
case 18:x=21
return A.t(r.Dk(),$async$oT)
case 21:x=19
break
case 20:x=22
return A.t(r.Dh(),$async$oT)
case 22:case 19:case 11:case 7:s.push(5)
x=4
break
case 3:s=[2]
case 4:u=2
if(r.c!=null)r.I(new C.aPh(r))
x=s.pop()
break
case 5:case 1:return A.x(v,w)
case 2:return A.w(t.at(-1),w)}})
return A.y($async$oT,w)}}
var z=a.updateTypes(["az<~>()","~(bM<o0>)"])
C.aPf.prototype={
$1(d){A.aeU("web_mall_manager_dashboard")
return I.bcf()},
$S:17}
C.aPj.prototype={
$1(d){A.aeU("web_mall_manager_dashboard")
return I.bcf()},
$S:17}
C.aPi.prototype={
$0(){return this.a.z=D.fp},
$S:0}
C.aPA.prototype={
$2(d,e){if(d)return
A.aT(this.a,!1).lc(A.cr(new C.aPr(),null,y.b))},
$S:100}
C.aPr.prototype={
$1(d){return B.e0},
$S:44}
C.aPz.prototype={
$2(d,e){var x,w,v,u=this,t=null,s=u.a,r=u.b,q=u.c,p=y.u,o=A.b([D.aYi,B.bN,D.b6P,B.b5,A.u(s.ay5(r,q),t,t,t,D.b_N,B.bK,t,t),B.bN],p),n=!r
if(n&&!q)o.push(s.ahU())
o.push(B.d0)
x=!n||q
w=s.d
o.push(A.cS(t,B.aB,!1,t,!0,B.K,t,A.cY(),w,t,t,t,t,t,2,A.fr(t,new E.e8(4,A.an(8),B.cS),t,t,t,t,t,t,!0,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,"manager@mall.com",t,t,t,t,t,t,t,t,"Registered Email",!0,!0,!1,t,D.a0V,t,t,t,t,t,t,t,t,t,t,t,t),B.ab,!0,t,!0,t,!1,t,B.aA,t,t,t,t,B.uC,t,t,t,1,t,t,!1,"\u2022",t,t,t,t,t,!1,t,t,x,t,!0,t,B.at,t,t,t,t,t,t,t,t,t,t,t,t,!0,B.ai,t,B.au,t,t,t,t))
o.push(B.aj)
if(s.z===D.fp)B.l.R(o,A.b([s.wK(s.e,"Password",!s.x,new C.aPs(s))],p))
if(s.z===D.iy&&n)B.l.R(o,A.b([s.wK(s.e,"Create Password",!s.x,new C.aPt(s)),B.aj,s.wK(s.f,"Confirm Password",!s.y,new C.aPu(s))],p))
if(s.z===D.iy&&r){x=u.d
v=x.Q
if(v==null)v=B.n.W(w.a.a)
B.l.R(o,A.b([s.Ve(v,x.z,x.as),B.aj,s.Vg()],p))}if(s.z===D.ky&&!q)B.l.R(o,A.b([B.b5],p))
if(s.z===D.ky&&q){x=u.d
v=x.Q
w=v==null?B.n.W(w.a.a):v
B.l.R(o,A.b([s.Ve(w,x.z,x.as),B.aj,s.Vg(),B.aj,s.wK(s.e,"Create New Password",!s.x,new C.aPv(s)),B.aj,s.wK(s.f,"Confirm New Password",!s.y,new C.aPw(s))],p))}o.push(B.d0)
p=s.w?t:s.gav8()
x=A.lT(t,t,B.f3,t,t,t,t,t,t,B.D,t,t,B.eE,t,t,t,t,t,t,t)
o.push(A.bc(A.jV(s.w?M.us:A.u(s.av9(r,q),t,t,t,L.fg,t,t,t),p,x),t,1/0))
o.push(B.b5)
if(s.z===D.fp&&n&&!q)o.push(new A.dx(B.e_,t,t,A.cx(D.b5v,t,t,new C.aPx(s,d),t,t),t))
if(!n||q)o.push(new A.dx(B.e_,t,t,A.cx(D.b3t,t,t,new C.aPy(s,u.d),t,t),t))
return A.f8(A.em(new A.d9(new A.aa(0,560,e.d,1/0),A.a7(o,B.cF,B.eJ,B.y),t),t,t),t,B.dm,B.an)},
$S:690}
C.aPs.prototype={
$0(){var x=this.a
x.I(new C.aPq(x))},
$S:0}
C.aPq.prototype={
$0(){var x=this.a
return x.x=!x.x},
$S:0}
C.aPt.prototype={
$0(){var x=this.a
x.I(new C.aPp(x))},
$S:0}
C.aPp.prototype={
$0(){var x=this.a
return x.x=!x.x},
$S:0}
C.aPu.prototype={
$0(){var x=this.a
x.I(new C.aPo(x))},
$S:0}
C.aPo.prototype={
$0(){var x=this.a
return x.y=!x.y},
$S:0}
C.aPv.prototype={
$0(){var x=this.a
x.I(new C.aPn(x))},
$S:0}
C.aPn.prototype={
$0(){var x=this.a
return x.x=!x.x},
$S:0}
C.aPw.prototype={
$0(){var x=this.a
x.I(new C.aPm(x))},
$S:0}
C.aPm.prototype={
$0(){var x=this.a
return x.y=!x.y},
$S:0}
C.aPx.prototype={
$0(){E.bW(this.b,!1,y.n).rE()
var x=this.a
x.r.eg(0,B.cK)
x.e.eg(0,B.cK)
x.f.eg(0,B.cK)
x.I(new C.aPl(x))},
$S:0}
C.aPl.prototype={
$0(){return this.a.z=D.ky},
$S:0}
C.aPy.prototype={
$0(){this.b.rE()
var x=this.a
x.r.eg(0,B.cK)
x.e.eg(0,B.cK)
x.f.eg(0,B.cK)
x.I(new C.aPk())},
$S:0}
C.aPk.prototype={
$0(){},
$S:0}
C.aPe.prototype={
$1(d){var x=this.a,w=x.c
w.toString
E.bW(w,!1,y.n).rE()
x.r.eg(0,B.cK)
x.e.eg(0,B.cK)
x.f.eg(0,B.cK)
x.I(new C.aPd(x,d))},
$S:z+1}
C.aPd.prototype={
$0(){var x=this.b
return this.a.z=x.ga1(x)},
$S:0}
C.aPg.prototype={
$0(){return this.a.w=!0},
$S:0}
C.aPh.prototype={
$0(){return this.a.w=!1},
$S:0};(function installTearOffs(){var x=a._instance_0u
x(C.Or.prototype,"gav8","oT",0)})();(function inheritance(){var x=a.inherit,w=a.inheritMany
x(C.o0,A.tA)
x(C.rp,A.X)
x(C.Or,A.a0)
w(A.it,[C.aPf,C.aPj,C.aPr,C.aPe])
w(A.lL,[C.aPi,C.aPs,C.aPq,C.aPt,C.aPp,C.aPu,C.aPo,C.aPv,C.aPn,C.aPw,C.aPm,C.aPx,C.aPl,C.aPy,C.aPk,C.aPd,C.aPg,C.aPh])
w(A.mQ,[C.aPA,C.aPz])})()
A.u1(b.typeUniverse,JSON.parse('{"rp":{"X":[],"c":[]},"Or":{"a0":["rp"]}}'))
var y={i:A.a6("j7<o0>"),u:A.a6("q<c>"),n:A.a6("m8"),E:A.a6("O"),F:A.a6("o0"),v:A.a6("q6"),b:A.a6("@"),q:A.a6("~")};(function constants(){var x=a.makeConstList
D.a0V=new A.bO(B.yz,null,null,null,null)
D.a0k=new A.aF(62589,"MaterialIcons",!1)
D.a14=new A.bO(D.a0k,null,null,null,null)
D.fp=new C.o0(0,"signIn")
D.b5V=new A.P("Sign In",null,null,null,null,null,null,null,null,null)
D.T_=new F.j7(D.fp,D.b5V,y.i)
D.iy=new C.o0(1,"signUp")
D.b5m=new A.P("Sign Up",null,null,null,null,null,null,null,null,null)
D.T2=new F.j7(D.iy,D.b5m,y.i)
D.ky=new C.o0(2,"forgotPassword")
D.b3J=new A.P("Forgot Password",null,null,null,null,null,null,null,null,null)
D.T0=new F.j7(D.ky,D.b3J,y.i)
D.aOV=x([D.T_,D.T2,D.T0],A.a6("q<j7<o0>>"))
D.aYi=new A.ta(88,B.c7,B.cE,null)
D.b_N=new A.p(!0,B.fY,null,null,null,null,14,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
D.b16=new A.p(!0,null,null,null,null,null,15,B.bf,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
D.PV=new A.p(!0,H.dj,null,null,null,null,12,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
D.W_=new A.o(1,0.48627450980392156,0.35294117647058826,0,B.u)
D.b2H=new A.p(!0,D.W_,null,null,null,null,null,B.b_,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
D.b3p=new A.P("Mall Manager",null,null,null,null,null,null,null,null,null)
D.b3t=new A.P("Use another email",null,null,null,null,null,null,null,null,null)
D.b4a=new A.P("Registered email",null,D.PV,null,null,null,null,null,null,null)
D.b5v=new A.P("Forgot password?",null,null,null,null,null,null,null,null,null)
D.b0P=new A.p(!0,null,null,null,null,null,24,B.b_,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
D.b6P=new A.P("Mall Manager Portal",null,D.b0P,B.bK,null,null,null,null,null,null)})()};
(a=>{a["tCKFgoAgisdjUoS3QHuz33g71KE="]=a.current})($__dart_deferred_initializers__);