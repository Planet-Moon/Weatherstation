function [P] = calc_pressure_T_UP(T,UP,oss)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
AC1 = 8196;
AC2 = -1111;
AC3 = -14369;
AC4 = 34420;
AC5 = 25620;
AC6 = 18884;
B1 = 6515;
B2 = 41;
MB = -32768;
MC = -11786;
MD = 2442;

T = T * 10;
B5 = T * pow2(4) - 8;

B6 = B5 - 4000;
X1 = (B2 .* ((B6.^2)/pow2(12)))./pow2(11);
X2 = AC2 .* B6 / pow2(11);
X3 = X1 + X2;
B3 = (((AC1 .* 4 + X3)*pow2(oss))+2)./4;
X1 = AC3 .* B6 / pow2(13);
X2 = (B1 .* ((B6.^2)./pow2(12)))./pow2(16);
X3 = ((X1+X2)+2)./4;
B4 = AC4 .* (X3 + 32768)./pow2(15);
B7 = (UP - B3).*(50000/pow2(oss));

p = zeros(size(B7));
greater = find(B7 < 0x80000000);
p(greater) = (B7(greater)*2)./B4(greater);
less = find(B7 <= 0x8000000);
p(less) = (B7(less)./B4(less))*2;

X1 = (p/pow2(8)).^2;
X1 = (X1 * 3038)/pow2(16);
X2 = (-7357 * p)/pow2(16);
P = p + (X1 + X2 + 3791)/pow2(4);

end

