objects = accum_strategy1_bad accum_strategy2_bad accum_strategy3_1 accum_strategy3_2 accum_strategy3_3 accum_strategy3_4

all: $(objects)

$(objects): %: %.cpp
	icpx -fsycl $< -o $@ -Wall -O3

clean:
	rm -f $(objects)
