// Greg Stitt
// University of Florida
//
// matrix_add_dynamic1.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code, which performs matrix addition:
//
// for (int i=0; i < NUM_ROWS; i++)
//   for (int j=0; j < NUM_COLS; j++) 
//     out[i][j] = in1[i][j] + in2[i][j];
//
// This implementation shows how create the matrices correctly for
// dynamically sized matrices whose dimensions are given as command line
// parameters.OA

#include <iostream>
#include <array>
#include <iomanip>
#include <cstdlib>
#include <string>

#include <CL/sycl.hpp>

class matrix_add;

void print_usage(const std::string &name) {

  std::cout << name << " num_rows num_cols (both must be positive)." << std::endl;
}

int main(int argc, char* argv[]) { 

  size_t num_rows;
  size_t num_cols;
  
  if (argc != 3) {
    print_usage(argv[0]);
    return 1;    
  }
  else {

    int rows = atoi(argv[1]);
    int cols = atoi(argv[2]);
    if (rows < 1 || cols < 1) {
      print_usage(argv[0]);
      return 1;
    }

    num_rows = rows;
    num_cols = cols;
  }

  // CHANGES FROM PREVIOUS EXAMPLE
  // For dynamically sized 2D arrays, we have to create a large 1D array
  // to ensure that the data is stored sequentially. We then have to
  // manually do the row-major ordering indexing anytime we access these
  // arrays.
  int *in1_h = new int[num_rows*num_cols];
  int *in2_h = new int[num_rows*num_cols];
  int *out_h = new int[num_rows*num_cols];
  int *correct_out = new int[num_rows*num_cols];

  // A common alternative to 2D arrays is to use pointers to pointers:
  //int **in1_h = new int*[num_rows];

  // And then do something like this to create the columns:
  //for (int i=0; i < num_rows; i++)
  //  in1_h[i] = new int[num_cols];

  // However, that approach will not work here for the same reason
  // vectors of vectors didn't work: although the data in each
  // individual array is stored sequentially, the collection of
  // arrays is not. Basically, each individual row will be stored
  // in different sections of memory.
  
  for (size_t i=0; i < num_rows; i++) {
    for (size_t j=0; j < num_cols; j++) {
      in1_h[i*num_cols + j] = i;
      in2_h[i*num_cols + j] = j;
      out_h[i*num_cols + j] = 0;
      correct_out[i*num_cols + j] = i + j;
    }
  }

  try {
    cl::sycl::queue queue(cl::sycl::default_selector_v);

    // CHANGES FROM PREVIOUS EXAMPLE
    // Since the dynamic 1D array is just an int*, we don't need any casting here now.
    cl::sycl::buffer<int, 2> in1_buf(in1_h, cl::sycl::range<2> {num_rows, num_cols} );
    cl::sycl::buffer<int, 2> in2_buf(in2_h, cl::sycl::range<2> {num_rows, num_cols} );
    cl::sycl::buffer<int, 2> out_buf(out_h, cl::sycl::range<2> {num_rows, num_cols} );
    
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor in1_d(in1_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor in2_d(in2_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor out_d(out_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class matrix_add>(cl::sycl::range<2> { num_rows, num_cols }, [=](cl::sycl::id<2> id) {
	    size_t x = id[0];
	    size_t y = id[1];
	    out_d[x][y] = in1_d[x][y] + in2_d[x][y];
	  });

      });

    queue.wait_and_throw();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    delete[] in1_h;
    delete[] in2_h;
    delete[] out_h;
    delete[] correct_out;
    return 1;
  }
  
  for (size_t i=0; i < num_rows; i++) {
    for (size_t j=0; j < num_cols; j++) {
      std::cout << std::setw(5) << out_h[i*num_cols + j] << " ";
    }
    std::cout << std::endl;
  }

  bool failed = false;
  for (size_t i=0; i < num_rows; i++) {
    for (size_t j=0; j < num_cols; j++) {
      if (out_h[i*num_cols + j] != correct_out[i*num_cols + j]) {
	std::cout << "ERROR: Execution failed." << std::endl;
	failed = true;
	break;
      }
    }
  }

  if (!failed)
    std::cout << "SUCCESS!" << std::endl;

  // CHANGES FROM PREVIOUS VERSION
  // Release the memory we allocated for the matrices.
  delete[] in1_h;
  delete[] in2_h;
  delete[] out_h;
  delete[] correct_out;
  return 0;
}
