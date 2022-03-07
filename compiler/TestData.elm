module TestData exposing (..)


m1 =
    """
\\begin{theorem}
  this is a test.
  
  $$
  c^2
  $$

  Blah blah
  
\\end{theorem}
"""


m1b =
    """
\\begin{theorem}
  this is a test.
  
  $$
  c^2
  $$

  Blah blah

"""


m2 =
    """
\\begin{theorem}
  this is a test.
  
  $$
  c^2
  $$
  
\\end{theorem}

\\begin{theorem}
  this is a test.
  
  $$
  c^2
  $$
  
\\end{theorem}
"""


l1 =
    """| theorem
  this is a test.
  
  $$
  c^2
  $$

"""


l2 =
    """| theorem
  TEST 1
  
  $$
  x^2
  $$

| theorem
  TEST 2
  
  $$
  y^2
  $$
"""
