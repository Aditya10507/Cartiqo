((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,B,C={e7:function e7(d,e,f){this.b=d
this.c=e
this.a=f},
bW(d,e,f){var y,x=f.h("xK<0?>?").a(d.hR(f.h("hV<0?>"))),w=x==null
if(w&&!f.b(null))A.a2(new C.YU(A.cz(f),A.D(d.gaQ())))
if(e)d.N(f.h("hV<0?>"))
y=w?null:x.gwP().gp(0)
if($.bgN()){if(!f.b(y))throw A.f(new C.YV(A.cz(f),A.D(d.gaQ())))
return y}return y==null?f.a(y):y},
YV:function YV(d,e){this.a=d
this.b=e},
YU:function YU(d,e){this.a=d
this.b=e}}
J=c[1]
A=c[0]
B=c[2]
C=a.updateHolder(c[10],C)
C.e7.prototype={
gnW(){return!0},
On(d){var y=d==null?this.a:d
return new C.e7(this.b,this.c,y)},
glD(){var y=this.a.gdC()
return new A.ak(y,y,y,y)},
aI(d,e){var y=this.a.aI(0,e)
return new C.e7(this.b*e,this.c.a9(0,e),y)},
dZ(d,e){var y,x
if(d instanceof C.e7){y=A.lB(d.c,this.c,e)
y.toString
x=A.bA(d.a,this.a,e)
return new C.e7(d.b,y,x)}return this.Bo(d,e)},
e_(d,e){var y,x
if(d instanceof C.e7){y=A.lB(this.c,d.c,e)
y.toString
x=A.bA(this.a,d.a,e)
return new C.e7(d.b,y,x)}return this.Bp(d,e)},
j2(d,e){var y=A.cj($.ab().r)
y.aj(new A.fD(this.c.du(d).cO(-this.a.gdC())))
return y},
e9(d,e){var y=A.cj($.ab().r)
y.aj(new A.fD(this.c.du(d)))
return y},
f_(d,e,f,g){d.dM(this.c.du(e),f)},
ghn(){return!0},
H9(a7,a8,a9,b0,b1,b2){var y,x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4=this.a,a5=a4.hr(),a6=this.c.du(a8)
a4=a4.b*a4.d/2
y=a6.cO(a4)
if(b1==null||a9<=0||b0===0)a7.dM(y,a5)
else{x=this.b
w=A.a1(0,a9+x*2,b0)
w.toString
switch(b2.a){case 0:x=b1+x-w
break
case 1:x=b1-x
break
default:x=null}v=a6.c-a6.a
x=Math.max(0,x)
u=y.ID()
t=u.a
s=u.b
r=u.e
q=u.f
p=u.c
o=u.r
n=o*2
m=p-n
l=u.w
k=new A.w(m,s,m+n,s+l*2)
n=u.x
m=n*2
j=p-m
i=u.d
h=u.y
g=h*2
f=i-g
e=u.Q
d=e*2
a0=i-d
a1=u.z
a2=A.cj($.ab().r)
if(!new A.b6(r,q).k(0,B.ah))a2.aj(new A.qg(new A.w(t,s,t+r*2,s+q*2),3.141592653589793,Math.acos(A.M(1-x/r,0,1))))
else a2.aj(new A.e_(t+a4,s))
if(x>r)a2.aj(new A.bU(x,s))
a4=x+w
if(a4<v-o){a2.aj(new A.e_(a4,s))
a2.aj(new A.bU(p-o,s))
if(!new A.b6(o,l).k(0,B.ah))a2.aj(new A.qg(k,4.71238898038469,1.5707963267948966))}else if(a4<v){a3=Math.asin(A.M(1-(v-a4)/o,0,1))
a2.aj(new A.qg(k,4.71238898038469+a3,1.5707963267948966-a3))}if(!new A.b6(n,h).k(0,B.ah))a2.aj(new A.e_(p,s+l))
a2.aj(new A.bU(p,i-h))
if(!new A.b6(n,h).k(0,B.ah))a2.aj(new A.qg(new A.w(j,f,j+m,f+g),0,1.5707963267948966))
a2.aj(new A.bU(t+a1,i))
if(!new A.b6(a1,e).k(0,B.ah))a2.aj(new A.qg(new A.w(t,a0,t+a1*2,a0+d),1.5707963267948966,1.5707963267948966))
a2.aj(new A.bU(t,s+q))
a7.e4(a2,a5)}},
fb(d,e,f){return this.H9(d,e,0,0,null,f)},
k(d,e){var y=this
if(e==null)return!1
if(y===e)return!0
if(J.a3(e)!==A.D(y))return!1
return e instanceof C.e7&&e.a.k(0,y.a)&&e.c.k(0,y.c)&&e.b===y.b},
gC(d){return A.a_(this.a,this.c,this.b,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c)}}
C.YV.prototype={
j(d){return"A provider for "+this.a.j(0)+" unexpectedly returned null."},
$icH:1}
C.YU.prototype={
j(d){return"Provider<"+this.a.j(0)+"> not found for "+this.b.j(0)},
$icH:1}
var z=a.updateTypes([]);(function inheritance(){var y=a.inherit,x=a.inheritMany
y(C.e7,A.jZ)
x(A.R,[C.YV,C.YU])})()
A.tO(b.typeUniverse,JSON.parse('{"e7":{"jZ":[],"cV":[]},"YV":{"cH":[]},"YU":{"cH":[]}}'));(function lazyInitializers(){var y=a.lazyFinal
y($,"bAy","bgN",()=>!A.a8("H<n>").b(A.b([],A.a8("q<n?>"))))})()};
(a=>{a["deKbDzzPBjJ8Q86SUAV9F1JqtHo="]=a.current})($__dart_deferred_initializers__);