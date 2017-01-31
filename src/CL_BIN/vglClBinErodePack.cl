/** Dilation of img_input by mask. Result is stored in img_output.

  */

// SHAPE img_shape (img_input->vglShape->asVglClShape())
// ARRAY convolution_window [window_size_x*window_size_y]
// SCALAR window_size_x
// SCALAR window_size_y

#include "vglClShape.h"

__kernel void vglClBinErodePack(__read_only image2d_t img_input,
                             __write_only image2d_t img_output,
                             __constant float* convolution_window, 
                             int window_size_x, 
                             int window_size_y,
                             __constant VglClShape* img_shape)
{
    int2 coords = (int2)(get_global_id(0), get_global_id(1));
    const sampler_t smp = CLK_NORMALIZED_COORDS_FALSE | //Natural coordinates
                          CLK_ADDRESS_CLAMP_TO_EDGE |   //Clamp to next edge
                          CLK_FILTER_NEAREST;           //Don't interpolate
    
    int w_r = floor((float)window_size_x / 2.0f);
    int h_r = floor((float)window_size_y / 2.0f);
    int w_img = img_shape->shape[VGL_SHAPE_WIDTH];
    int ws_img = img_shape->offset[VGL_SHAPE_HEIGHT] - 1;
    int h_img = img_shape->shape[VGL_SHAPE_HEIGHT];
    int pad = ((w_r / 8) + 1) * 8; // Avoids negative remainder.
    int i_l = 0;
    uint4 boundary = 255;
    unsigned char result = 255;
    unsigned char aux;
    int bit = 0;
    for(int i_w = -h_r; i_w <= h_r; i_w++)
    {
      for(int j_w = -w_r; j_w <= w_r; j_w++)
      {
        if (!(convolution_window[i_l] == 0))
	{
          int i_img = coords.y + i_w;
          int j_img = coords.x;
          uint4 p; 
          if (j_w < 0)
          {
            p = read_imageui(img_input, smp, (int2)(j_img, i_img));
            aux =       p.x >> ( -j_w);
            if (j_img == 0)
              p = boundary;
            else
              p = read_imageui(img_input, smp, (int2)(j_img - 1, i_img));
            aux = aux | p.x << (8+j_w);
            result = result & aux;
          }
          else if (j_w > 0)
          {
            p = read_imageui(img_input, smp, (int2)(j_img, i_img));
            aux =       p.x << (  j_w);
            if (j_img == ws_img)
              p = boundary;
            else
              p = read_imageui(img_input, smp, (int2)(j_img + 1, i_img));
            aux = aux | p.x >> (8-j_w);
            result = result & aux;
          }
          else
          {
            p = read_imageui(img_input, smp, (int2)(j_img, i_img));
            result = result & p.x;
          }
	}
        i_l++;
      }
    }
    write_imageui(img_output, coords, result);
}