%George Conwell
%ECSE 6680, 3/18/2024

Fpass = 0.2; 
Fstop = 0.23;
Ast = 80;
d = designfilt('lowpassfir','PassbandFrequency',Fpass,...
  'StopbandFrequency',Fstop,'StopbandAttenuation',Ast);
hfvt = fvtool(d);

lowpassFIR = dsp.FIRFilter(Numerator=x); %x is quantized FIR coefficients
yes = fvtool(lowpassFIR);