#!/usr/bin/python3
# This script takes 2 arguements:
# 1) big image
# 2) small image
# Example:
# python3 find-center.py full_screenshot.png screenshot_of_webcam_button.png
# It prints coordinates of the center of the small image inside the big one.
# Based on:
# https://opencv24-python-tutorials.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_template_matching/py_template_matching.html

import sys
# python3-opencv
import cv2

img = cv2.imread(sys.argv[1], 0)
template = cv2.imread(sys.argv[2], 0)
# cv2.TM_CCOEFF works ok if Chromium is without address bar (--start-fullscreen),
# but gives incorrect coordinates if it is with address bar (--start-maximized);
# cv2.TM_CCOEFF_NORMED seems to work in both cases.
# Did not test other methods.
method = eval('cv2.TM_CCOEFF_NORMED')
res = cv2.matchTemplate(img, template, method)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
#top_left = max_loc
width, height = template.shape[::-1]
#bottom_right = (top_left[0] + width, top_left[1] + height)
top_left_x = max_loc[0]
buttom_left_x = max_loc[0] + height
medium_x = (top_left_x + buttom_left_x)/2
top_left_y = max_loc[1]
buttom_left_y = max_loc[1] + width
medium_y = (top_left_y + buttom_left_y)/2
print("%d %d" %(medium_x, medium_y))
