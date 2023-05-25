// Greg Stitt
// University of Florida
//
// matrix_add_bad.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code, which performs matrix addition:
//
// for (int i=0; i < NUM_ROWS; i++)
//   for (int j=0; j < NUM_COLS; j++) 
//     out[i][j] = in1[i][j] + in2[i][j];
//
// This implementation uses an incorrect method of storing the inputs on the
// host, with the key point being that an data transferred to a device has to
// be stored sequentially in memory.

#include <iostream>
#include <vector>
#include <iomanip>

#include <CL/sycl.hpp>

const int NUM_ROWS = 10;
const int NUM_COLS = 5;

class matrix_add;

int main(int argc, char* argv[]) { 

  // Since we are working with matrices, we could potentially represent a
  // matrix as a vector of vectors, as show below. Each variable creates
  // a vector with NUM_ROWS elements, where each element is a vector
  // with NUM_COLS elements.
  //
  // Although convenient, this code has a significant problem when used
  // with SYCL (or any similar approach).
  std::vector<std::vector<int> > in1_h(NUM_ROWS, std::vector<int>(NUM_COLS));
  std::vector<std::vector<int> > in2_h(NUM_ROWS, std::vector<int>(NUM_COLS));
  std::vector<std::vector<int> > out_h(NUM_ROWS, std::vector<int>(NUM_COLS));
  std::vector<std::vector<int> > correct_out(NUM_ROWS, std::vector<int>(NUM_COLS));

  // Initialize the matrices.
  for (size_t i=0; i < NUM_ROWS; i++) {
    for (size_t j=0; j < NUM_COLS; j++) {
      in1_h[i][j] = i;
      in2_h[i][j] = j;
      out_h[i][j] = 0;
      correct_out[i][j] = i + j;
    }
  }

  try {
    cl::sycl::queue queue(cl::sycl::default_selector_v);

    // To more convenient work with a matrix, we create a 2D buffer for each matrix.
    // IMPORTANT: these lines will not compile for a very important reason. The first
    // parameter to the buffer constructor is an int* (for this example). in1_h.data()
    // returns a point to whatever type is used in the vector, which is another
    // vector. Even if this did compile, it would not work because SYCL (and other approaches)
    // data transferred betweeen devices to be stored sequentially in memory.
    // This might seem confusing because std::vector does in fact store data sequentially
    // in memory. The problem is that each individual vector is stored sequentially. However,
    // it is incredibly unlikely that all the vectors in each dimenstion happen to be stored
    // in row-major order because std::vector dynamically allocate memory. So, think of
    // a vector of vectors, as having each sub-vector stored sequentially, but the sub-vectors
    // are not stored one after the other. They are stored in completely different locations
    // in memory. As a result, we can't do this.
    cl::sycl::buffer<int, 2> in1_buf(in1_h.data(), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> in2_buf(in2_h.data(), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );
    cl::sycl::buffer<int, 2> out_buf(out_h.data(), cl::sycl::range<2> {NUM_ROWS, NUM_COLS} );    
    
    queue.submit([&](cl::sycl::handler& handler) {

	// These accessors don't use explicit template parameters,
	// and inherit the type and dimension from the buffer parameter, which makes
	// them a 2D accessor that can be treated like a 2D array.
	cl::sycl::accessor in1_d(in1_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor in2_d(in2_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor out_d(out_buf, handler, cl::sycl::write_only);

	// Here we use a 2D range to get work-item ids with 2 dimensions.
	handler.parallel_for<class matrix_add>(cl::sycl::range<2> { NUM_ROWS, NUM_COLS }, [=](cl::sycl::id<2> id) {

	    // Get the current row and col of the work-item.
	    size_t x = id[0];
	    size_t y = id[1];

	    // Perform the add for a single element of the matrices.
	    // Note that with a 2D accessor and buffer, we don't need to
	    // explicitly calculate the 1D index based on row-major
	    // ordering.
	    out_d[x][y] = in1_d[x][y] + in2_d[x][y];
	  });

      });

    queue.wait_and_throw();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }

  // Print the output matrix.
  for (size_t i=0; i < NUM_ROWS; i++) {
    for (size_t j=0; j < NUM_COLS; j++) {
      std::cout << std::setw(5) << out_h[i][j] << " ";
    }
    std::cout << std::endl;
  }

  // Check for correctness.
  for (size_t i=0; i < NUM_ROWS; i++) {
    for (size_t j=0; j < NUM_COLS; j++) {
      if (out_h[i][j] != correct_out[i][j]) {
	std::cout << "ERROR: Execution failed." << std::endl;
	return 1;
      }
    }
  }
  
  std::cout << "SUCCESS!" << std::endl;
    
  return 0;
}
