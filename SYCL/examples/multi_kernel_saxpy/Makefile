objects = saxpy_multi_kernel saxpy_multi_device saxpy_scatter

all: $(objects)

$(objects): %: %.cpp
	icpx -fsycl $< -o $@ -Wall -O3

clean:
	rm -f $(objects)
