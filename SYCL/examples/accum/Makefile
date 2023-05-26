objects = accum_strategy1_bad accum_strategy2_bad

all: $(objects)

$(objects): %: %.cpp
	icpx -fsycl $< -o $@ -Wall -O3

clean:
	rm -f $(objects)
