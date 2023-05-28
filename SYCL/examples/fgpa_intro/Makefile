objects = saxpy_single saxpy_unroll saxpy_pipe

all: $(objects)

$(objects): %: %.cpp
	icpx -fsycl $< -o $@ -Wall -O3

clean:
	rm -f $(objects)
