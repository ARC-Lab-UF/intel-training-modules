objects = vector_add_bad vector_add1 vector_add2 vector_add_terse

all: $(objects)

$(objects): %: %.cpp
	icpx -fsycl $< -o $@ -Wall -O3

clean:
	rm -f $(objects)
