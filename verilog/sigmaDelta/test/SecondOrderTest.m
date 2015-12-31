n = 2^13;

num_lines = 2;

h = zeros(n,num_lines);
w = zeros(n,num_lines);

selNoise = 1;
if (selNoise == 0)
  b = 2;
else
  b = 1;
endif


k0 = 1; k1 = 2.33; i=1;
[h(:,i) w(:,i)] = freqz(selNoise*[1 -2 0] + [0 0 b],[1 k1 k0-k1], n);

selNoise = 0;
if (selNoise == 0)
  b = 2;
else
  b = 1;
endif
i=2;
[h(:,i) w(:,i)] = freqz(selNoise*[1 -2 0] + [0 0 b],[1 k1 k0-k1], n);

plot(w/pi, to_db(h));
legend('1','2')