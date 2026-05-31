((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,B,C={e8:function e8(d,e,f){this.b=d
this.c=e
this.a=f},
bW(d,e,f){var y,x=f.h("y_<0?>?").a(d.hS(f.h("hW<0?>"))),w=x==null
if(w&&!f.b(null))A.a2(new C.Zp(A.cA(f),A.C(d.gaQ())))
if(e)d.N(f.h("hW<0?>"))
y=w?null:x.gwS().gp(0)
if($.bi8()){if(!f.b(y))throw A.f(new C.Zq(A.cA(f),A.C(d.gaQ())))
return y}return y==null?f.a(y):y},
Zq:function Zq(d,e){this.a=d
this.b=e},
Zp:function Zp(d,e){this.a=d
this.b=e}}
J=c[1]
A=c[0]
B=c[2]
C=a.updateHolder(c[10],C)
C.e8.prototype={
gnZ(){return!0},
Oy(d){var y=d==null?this.a:d
return new C.e8(this.b,this.c,y)},
glE(){var y=this.a.gdC()
return new A.ak(y,y,y,y)},
aI(d,e){var y=this.a.aI(0,e)
return new C.e8(this.b*e,this.c.a9(0,e),y)},
e_(d,e){var y,x
if(d instanceof C.e8){y=A.lG(d.c,this.c,e)
y.toString
x=A.bA(d.a,this.a,e)
return new C.e8(d.b,y,x)}return this.Br(d,e)},
e0(d,e){var y,x
if(d instanceof C.e8){y=A.lG(this.c,d.c,e)
y.toString
x=A.bA(this.a,d.a,e)
return new C.e8(d.b,y,x)}return this.Bs(d,e)},
j5(d,e){var y=A.ck($.ab().r)
y.aj(new A.fE(this.c.du(d).cO(-this.a.gdC())))
return y},
ea(d,e){var y=A.ck($.ab().r)
y.aj(new A.fE(this.c.du(d)))
return y},
f_(d,e,f,g){d.dN(this.c.du(e),f)},
ghp(){return!0},
Hl(a7,a8,a9,b0,b1,b2){var y,x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4=this.a,a5=a4.ht(),a6=this.c.du(a8)
a4=a4.b*a4.d/2
y=a6.cO(a4)
if(b1==null||a9<=0||b0===0)a7.dN(y,a5)
else{x=this.b
w=A.a1(0,a9+x*2,b0)
w.toString
switch(b2.a){case 0:x=b1+x-w
break
case 1:x=b1-x
break
default:x=null}v=a6.c-a6.a
x=Math.max(0,x)
u=y.IP()
t=u.a
s=u.b
r=u.e
q=u.f
p=u.c
o=u.r
n=o*2
m=p-n
l=u.w
k=new A.B(m,s,m+n,s+l*2)
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
a2=A.ck($.ab().r)
if(!new A.b6(r,q).k(0,B.ah))a2.aj(new A.qq(new A.B(t,s,t+r*2,s+q*2),3.141592653589793,Math.acos(A.M(1-x/r,0,1))))
else a2.aj(new A.e0(t+a4,s))
if(x>r)a2.aj(new A.bV(x,s))
a4=x+w
if(a4<v-o){a2.aj(new A.e0(a4,s))
a2.aj(new A.bV(p-o,s))
if(!new A.b6(o,l).k(0,B.ah))a2.aj(new A.qq(k,4.71238898038469,1.5707963267948966))}else if(a4<v){a3=Math.asin(A.M(1-(v-a4)/o,0,1))
a2.aj(new A.qq(k,4.71238898038469+a3,1.5707963267948966-a3))}if(!new A.b6(n,h).k(0,B.ah))a2.aj(new A.e0(p,s+l))
a2.aj(new A.bV(p,i-h))
if(!new A.b6(n,h).k(0,B.ah))a2.aj(new A.qq(new A.B(j,f,j+m,f+g),0,1.5707963267948966))
a2.aj(new A.bV(t+a1,i))
if(!new A.b6(a1,e).k(0,B.ah))a2.aj(new A.qq(new A.B(t,a0,t+a1*2,a0+d),1.5707963267948966,1.5707963267948966))
a2.aj(new A.bV(t,s+q))
a7.e5(a2,a5)}},
fc(d,e,f){return this.Hl(d,e,0,0,null,f)},
k(d,e){var y=this
if(e==null)return!1
if(y===e)return!0
if(J.a3(e)!==A.C(y))return!1
return e instanceof C.e8&&e.a.k(0,y.a)&&e.c.k(0,y.c)&&e.b===y.b},
gC(d){return A.Z(this.a,this.c,this.b,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c,B.c)}}
C.Zq.prototype={
j(d){return"A provider for "+this.a.j(0)+" unexpectedly returned null."},
$icu:1}
C.Zp.prototype={
j(d){return"Provider<"+this.a.j(0)+"> not found for "+this.b.j(0)},
$icu:1}
var z=a.updateTypes([]);(function inheritance(){var y=a.inherit,x=a.inheritMany
y(C.e8,A.k3)
x(A.O,[C.Zq,C.Zp])})()
A.u1(b.typeUniverse,JSON.parse('{"e8":{"k3":[],"cW":[]},"Zq":{"cu":[]},"Zp":{"cu":[]}}'));(function lazyInitializers(){var y=a.lazyFinal
y($,"bCl","bi8",()=>!A.a6("H<n>").b(A.b([],A.a6("q<n?>"))))})()};
(a=>{a["gzOuFox97Df3qLwZtnNDYBcq9F0="]=a.current})($__dart_deferred_initializers__);