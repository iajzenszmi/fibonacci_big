# fibonacci_big
very big fibonacci numbers ie 3000 terms
Great—let’s switch the Fibonacci to **quad precision** and make sure it never prints `Inf`, even when values overflow.

# What “real(16)” actually is

* On compilers that support IEEE **binary128 (quadruple precision)**, `real(16)` / `REAL128` is a 128-bit float (\~33–36 decimal digits, exponent range \~±4932). ([Wikipedia][1])
* Intel Fortran (ifx/ifort) maps `REAL(16)` to IEEE **binary128**; it’s explicitly documented. ([ahamodel.uib.no][2], [Intel Community][3])
* With gfortran, quad precision is available on most platforms via **libquadmath**; you should request kinds via `ISO_FORTRAN_ENV`/`SELECTED_REAL_KIND`, not hardcoded `real*16`. ([GCC][4], [Fortran Discourse][5])

# Portable quad-precision Fibonacci (clamped)

This version uses **REAL128** if available; otherwise it tries `selected_real_kind(33,4931)` (the usual request for binary128). If neither exists, it stops with a clear message.

```fortran
program fibonacci_qp_clamped
  use, intrinsic :: iso_fortran_env, only: real128
  use, intrinsic :: ieee_arithmetic
  implicit none

  integer :: n, i
  integer, parameter :: rk = real128              ! quad precision kind (if supported)
  real(rk) :: a, b, next, maxval

  print *, 'How many terms?'
  read *, n
  if (n <= 0) stop

  a = 0.0_rk
  b = 1.0_rk
  maxval = huge(0.0_rk)

  print '(ES28.18)', a
  if (n >= 2) print '(ES28.18)', b

  do i = 3, n
     ! Saturating add to avoid producing Inf in the first place
     if (b > maxval - abs(a)) then
        next = sign(maxval, a + b)
     else
        next = a + b
     end if
     ! Replace any non-finite (Inf/NaN) with +/-HUGE
     if (.not. ieee_is_finite(next)) next = sign(maxval, next)

     print '(ES28.18)', next
     a = b
     b = next
  end do
end program fibonacci_qp_clamped
```

### If your compiler doesn’t have `REAL128`

Some compilers don’t define `REAL128`. In that case, use `selected_real_kind(33,4931)` (≈ quad precision request). It returns `-1` if the kind isn’t supported—so you can guard it:

```fortran
program fibonacci_qp_selected
  use, intrinsic :: ieee_arithmetic
  implicit none
  integer, parameter :: qp = selected_real_kind(33,4931)
  ! Abort nicely if quad isn’t available
  integer, parameter :: rk = merge(qp, kind(1.0d0), qp > 0)
  if (qp < 0) then
     print *, 'Quad precision not supported on this compiler/target.'
     stop
  end if
  ! ...then same body as above but with kind rk...
end program fibonacci_qp_selected
```

* `REAL128` and `SELECTED_REAL_KIND` usage is the **recommended**, portable way to request kinds in Fortran instead of hardcoding `real*16`. ([GCC][4], [Fortran Wiki][6])

# Notes

* IEEE quadruple specifics (1 sign, 15-bit exponent, 113-bit significand → \~34 digits) explain why you can push overflow much further than double before clamping. ([Wikipedia][1])
* If you want to *verify* you’re really in quad, print `precision(0.0_rk)` and `range(0.0_rk)`; expect about 33 digits and exponent range around 4931 for binary128. (Those targets are the ones `selected_real_kind(33,4931)` asks for.) ([Fortran Wiki][6])

Want me to add a tiny self-check that prints the detected precision/range and which kind you actually got?

[1]: https://en.wikipedia.org/wiki/Quadruple-precision_floating-point_format?utm_source=chatgpt.com "Quadruple-precision floating-point format - Wikipedia"
[2]: https://ahamodel.uib.no/intel/GUID-9B3B811A-C16E-4978-88D2-0D6721CD3B76.html?utm_source=chatgpt.com "REAL (16) Constants"
[3]: https://community.intel.com/t5/Intel-Fortran-Compiler/Support-for-IEEE-extended-and-Quad-precision-in-Fortran/m-p/989026?utm_source=chatgpt.com "Yes, REAL (16) is the same as - Intel Communities"
[4]: https://gcc.gnu.org/onlinedocs/gfortran/KIND-Type-Parameters.html?utm_source=chatgpt.com "KIND Type Parameters (The GNU Fortran Compiler)"
[5]: https://fortran-lang.discourse.group/t/gfortran-quad-precision/6640?utm_source=chatgpt.com "Gfortran quad precision - Help - Fortran Discourse"
[6]: https://fortranwiki.org/fortran/show/Real%2Bprecision?utm_source=chatgpt.com "Real precision in Fortran Wiki"
