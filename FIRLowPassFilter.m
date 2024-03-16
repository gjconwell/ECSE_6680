Fpass = 0.2; 
Fstop = 0.23;
Ast = 80;
d = designfilt('lowpassfir','PassbandFrequency',Fpass,...
  'StopbandFrequency',Fstop,'StopbandAttenuation',Ast);
hfvt = fvtool(d);


x = d.Coefficients;
y = fft(x);
hmm = fvtool(y);