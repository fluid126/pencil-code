;  $Id: extra.pro,v 1.35 2004-02-26 15:54:24 ajohan Exp $
;
;  This routine calculates a number of extra variables
;
gamma=5./3.
gamma1=gamma-1.
;
@data/pc_constants.pro
;
;print,'calculate xx,yy,zz (comment out if there isnt enough memory!)'
xx = spread(x, [1,2], [my,mz])
yy = spread(y, [0,2], [mx,mz])
zz = spread(z, [0,1], [mx,my])
;
;  calculate extra stuff that may be of some convenience
;
if (iuu ne 0) then oo=curl(uu)
if (iaa ne 0) then bb=curl(aa)
if (iaa ne 0) then jj=curl2(aa)
xxx=x(l1:l2)
yyy=y(m1:m2)
zzz=z(n1:n2)
if (iuu ne 0) then uuu=reform(uu(l1:l2,m1:m2,n1:n2,*))
if (iuu ne 0) then ooo=reform(oo(l1:l2,m1:m2,n1:n2,*))
if (iaa ne 0) then aaa=reform(aa(l1:l2,m1:m2,n1:n2,*))
if (iaa ne 0) then bbb=reform(bb(l1:l2,m1:m2,n1:n2,*))
if (iaa ne 0) then jjj=reform(jj(l1:l2,m1:m2,n1:n2,*))
;
if (ilnrho ne 0) then begin
  llnrho=reform(lnrho(l1:l2,m1:m2,n1:n2))
  rho=exp(llnrho)
  if (iss eq 0) then begin
    cs2=cs20*exp(gamma1*llnrho) 
  end else begin
    sss=reform(ss(l1:l2,m1:m2,n1:n2))
    ; the following gives cs2,cp1tilde,eee,ppp
    @thermodynamics.pro
  end
;ajwm NOT SO SURE THE ENTHALPY IS CORRECT EITHER
  hhh=cs2/gamma1  ;(enthalpy)
;
end
;
if (iqrad ne 0) then QQrad=reform(Qrad(l1:l2,m1:m2,n1:n2))
if (iqrad ne 0) then SSrad=Srad0*(TTT/TT_ion)^4
if (iqrad ne 0) then kaprho=.25*exp(2*llnrho-lnrho_e_)*(TT_ion_/TTT)^1.5 $
                            *exp(TT_ion_/TTT)*yyH*(1.-yyH)*kappa0
;
if (iuu ne 0) then for j=0,2 do print,'j,ujrms=',j,sqrt(mean(uu(*,*,*,j)^2))
if (iuu ne 0) then print
;
;  calculate magnetic energy of mean field in the 3 directions
;
if (iaa ne 0) then begin
  default,b_ext,[0.,0.,0.]
  for j=0,2 do print,'j,Bjrms=',j,sqrt(mean(bb(*,*,*,j)^2))
  if ny ne 1 and nz ne 1 then begin
    for j=0,2 do bbb(*,*,*,j)=bbb(*,*,*,j)+b_ext(j)
    bmx=sqrt(mean(dot2_1d(means(means(bbb,3),2))))
    bmy=sqrt(mean(dot2_1d(means(means(bbb,3),1))))
    bmz=sqrt(mean(dot2_1d(means(means(bbb,2),1))))
    print
    print,'bmx,bmy,bmz=',bmx,bmy,bmz
    print
  endif
end
;
;  calculate vertical averages
;
if (iss ne 0) then begin
  if (nz gt 1 and nx gt 1 and ny gt 1) then begin
    cs2m=haver(cs2) & csm=sqrt(cs2m)
    rhom=haver(rho)
  end
end
;
;  passive scalar
;
if (ilncc ne 0) then begin
  llncc=reform(lncc(l1:l2,m1:m2,n1:n2))
  ccc=exp(llncc)
end

ndustspec = n_elements(ind)
if (ind(0) ne 0) then begin
  deltamd = par.deltamd
  md0 = par.md0
  rhods = par.rhods
  if (irhod(0) ne 0) then begin
    lmdvar=1
  endif else begin
    lmdvar=0
  endelse
  md      = fltarr(ndustspec)
  mdplus  = fltarr(ndustspec)
  mdminus = fltarr(ndustspec)
  ad      = fltarr(ndustspec)
  nd      = fltarr(nx,ny,nz,ndustspec)
  if (lmdvar) then rhod = fltarr(nx,ny,nz,ndustspec)

  for k=0,ndustspec-1 do begin
    sdust = strtrim(string(k),2)
    string = 'nd(*,*,*,'+sdust+') = nd'+sdust+'(l1:l2,m1:m2,n1:n2)'
    res = execute(string)
    if (lmdvar) then begin
      string = 'rhod(*,*,*,'+sdust+') = rhod'+sdust+'(l1:l2,m1:m2,n1:n2)'
      res = execute(string)
    endif
  endfor

  for i=0,ndustspec-1 do begin
    mdminus(i) = md0*deltamd^i
    mdplus(i)  = md0*deltamd^(i+1)
    md(i)      = 0.5*(mdplus(i)+mdminus(i))
    ad(i)      = (3*md(i)/(4*!pi*rhods))^(1/3.)
  endfor
  nd = reform(nd)
  if (lmdvar) then rhod = reform(rhod)
endif
;
END
