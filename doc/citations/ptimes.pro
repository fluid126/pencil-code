;$Id: add3.tex,v 1.502 2015/02/19 06:35:19 brandenb Exp $
if !d.name eq 'PS' then begin
  device,xsize=18,ysize=12,yoffset=3
  !p.charthick=3 & !p.thick=3 & !x.thick=3 & !y.thick=3
end
;
;  mv idl.ps fig/ptimes.ps
;  convert idl.ps ~/Figures/Pencil/2015/ptimes.png
;
!p.charsize=1.7
!x.margin=[6.1,.5]
!y.margin=[3.2,.5]
!x.title='!6year'
!y.title='!6number of papers'
;
a=rtable('times.txt',4)
n=a(0,*)
y=a(1,*)
c=a(2,*)
o=a(3,*)
print,n
print
print,total(n)
plot,y,n,ps=10,yr=[0,64];,xr=[2002,2016]
oplot,y,c,ps=10,col=122
oplot,y,o,ps=10,col=55
print,'total(n)=',total(n)
print,'total(c)=',total(c)
print,'total(o)=',total(o)
;
siz=2.0
xyouts,2003.6,58,'w/o Brandenburg',col=55,siz=siz
xyouts,2003.6,52,'comp & ref papers',col=122,siz=siz
END
