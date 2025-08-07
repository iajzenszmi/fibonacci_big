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
