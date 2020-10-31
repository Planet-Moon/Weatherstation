function [Mittelwert,Standardabweichung] = Mittelwertfilter(Input,N)
%Mittelwertfilter Berechnung des gleitenden Mittelwerts und
%Standardabweichung
%
%   Input: Eingangsvektor der Größe n x m
%   N: Ordnung des Filters
%
%   Mittelwert: Matrix des berechneten gleitenden Mittelwerts
%    der Größe n x m
%   Standardabweichung: Matrix der berechneten gleitenden
%    Standardabweichung der Größe n x m
Input_size = size(Input);
Mittelwert = zeros(Input_size);
Standardabweichung = zeros(Input_size(1),Input_size(2));
for i = 1:Input_size(1)
    for j = floor(N/2):Input_size(2)-ceil(N/2)
        Mittelwert(i,j) = mean(Input(i,j-floor(N/2)+1:j+ceil(N/2)));
        Standardabweichung(i,j) = std(Input(i,j-floor(N/2)+1:j+ceil(N/2)));
    end
    Mittelwert(i,j+1:j+ceil(N/2)) = Mittelwert(i,j);
    Standardabweichung(i,j+1:j+ceil(N/2)) = Standardabweichung(i,j);
    Mittelwert(i,1:floor(N/2)-1) = Mittelwert(i,floor(N/2));
    Standardabweichung(i,1:floor(N/2)-1) = Standardabweichung(i,floor(N/2));
end
end

