!------------------------------------------------------------------------------
! NASA/GSFC, CISTO, Code 606, Advanced Software Technology Group
!------------------------------------------------------------------------------
!
!*MODULE: PFL_FormatToken
!
!> @brief Provides constructor for a format token.
!
!> @author ASTG staff
!> @date 01 Jan 2015 - Initial Version  
!---------------------------------------------------------------------------
module PFL_FormatToken
   use PFL_Exception, only: throw
   implicit none
   private
   
   public :: FormatToken
   public :: KEYWORD_SEPARATOR
   public :: TEXT, POSITION, KEYWORD
   public :: EOT

   enum, bind(c)
      enumerator :: TEXT, POSITION, KEYWORD
   end enum

   character(len=1), parameter :: KEYWORD_SEPARATOR = ')'
   character(len=*), parameter :: LIST_DIRECTED_FORMAT = '*'

   type FormatToken
      integer :: type ! use enum
      character(len=:), allocatable :: text
      character(len=:), allocatable :: edit_descriptor
   end type FormatToken


   interface FormatToken
      module procedure newFormatToken
   end interface FormatToken

   character(len=1), parameter :: EOT = achar(003)

contains


   function newFormatToken(type, string) result(token)
      type (FormatToken) :: token
      integer, intent(in) :: type
      character(len=*), intent(in) :: string

      integer :: idx

      token%type = type

      select case (type)

      case (TEXT)
         token%text = string

      case (POSITION)
         select case (string)
         case (LIST_DIRECTED_FORMAT, '')
            token%edit_descriptor = '*'
         case default
            token%edit_descriptor = '(' // replace_newline(string) // ')'
         end select

      case (KEYWORD)
         idx = index(string, KEYWORD_SEPARATOR)
         if (idx == 1) then
            token%text = ''
            call throw(__FILE__,__LINE__,'FormatParser::keywordFormatHandler() - missing keyword in format specifier')
            return
         end if
         token%text = string(:idx-1)
         if (idx == len_trim(string)) then
            token%edit_descriptor = LIST_DIRECTED_FORMAT
         else if (string(idx+1:idx+1) == LIST_DIRECTED_FORMAT) then
            token%edit_descriptor = LIST_DIRECTED_FORMAT
         else
            token%edit_descriptor = '(' // replace_newline(string(idx+1:len_trim(string))) // ')'
         end if

      end select
      
   end function newFormatToken

   function replace_newline(string) result(new_string)
      character(:), allocatable :: new_string
      character(*), intent(in) :: string

      integer :: idx, n
      character(len=*), parameter :: FPP_SAFE_ESCAPE = '\\'
      character(len=1), parameter :: ESCAPE = FPP_SAFE_ESCAPE(1:1)

      new_string = string
      n = len(new_string)
      do
         idx = index(new_string,ESCAPE)
         if (idx == 0) exit

         if (idx == n) then
            call throw(__FILE__,__LINE__,'FormatToken - no such escape sequence: ' // ESCAPE)
            return
         end if
         if (any(new_string(idx+1:idx+1) == ['n','N'])) then ! replace with newline
            new_string = new_string(1:idx-1) // new_line('a') // new_string(idx+2:)
         else
            call throw(__FILE__,__LINE__,'FormatToken - no such escape sequence: ' // ESCAPE // new_string(idx+1:idx+1))
            return
         end if
         
      end do
   end function replace_newline

      

end module PFL_FormatToken
   
