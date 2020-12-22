#Datasegment
.data
#Cac dinh nghia bien				#Belong to 1913254
	dividend: .float 0
	divisor: .float 0
#Cac cau nhac nhap du lieu
	Nhac_dividend: .asciiz "Nhap so bi chia: "
	Nhac_divisor: .asciiz "Nhap so chia: "
	Nhac_quotient: .asciiz "Thuong: "
	nan: .asciiz "NaN"
	I: .asciiz "Infinity"
#Code segment
.text
.globl main
main:
#Nhap (syscall)
#Nhap dividend
	la $a0, Nhac_dividend	#In ra man hinh "Nhap so bi chia: "
	li $v0, 4
	syscall
	li $v0, 6		#Nhap dividend
	syscall 
	swc1 $f0, dividend	#Luu dividend vua nhap
#Nhap divisor
	la $a0, Nhac_divisor 	#In ra man hinh "Nhap so chia: "
	li $v0, 4
	syscall
	li $v0, 6		#Nhap so chia
	syscall
	swc1 $f0, divisor	#Luu divisor vua nhap
#Xu ly
  #Chuyen du lieu sang ma nhi phan
	lw $a1, dividend		# load the dividend into $a1
	lw $a2, divisor		# load the divisor into $a2
  #Check special case
   	beqz $a2, divisor0	#so sanh: $a2 = 0 thi nhay den divisor0 (divisor = 0)
   	beqz $a1, dividend0	#so sanh: $a1 = 0 thi nhay den dividend0 (dividend = 0)
   	j not0			#jump to not0. Tuc dividend va divisor deu khac 0
   divisor0:			#Truong hop divisor = 0
   	beqz $a1, both0		#check dividend equal to 0? if yes,  jump to both0
   	la $a0, Nhac_quotient	#If not,  dividend != 0,  in ra man hinh "Thuong: "
   	li $v0, 4	
   	syscall
   	
   	la $a0, I	
   	li $v0, 4	
   	syscall		#Xuat ket qua: Thuong: Infinity
   	j exit		#exit
   dividend0:			#Truong hop divisor khac 0 nhung dividend = 0
   	la $a0, Nhac_quotient	#In ra man hinh "Thuong: "
   	li $v0, 4
   	syscall
   	
   	li $a0, 0	#In ra "Thuong: 0" boi vi dividend = 0 && divisor != 0
   	li $v0, 1
   	syscall
   	j exit		#exit
   both0:			#Both dividend and divisor = 0
   	la $a0, Nhac_quotient	#In ra man hinh "Thuong: "
   	li $v0, 4
   	syscall
   	la $a0, nan	#In "Thuong: NaN" vi dividend va divisor = 0
   	li $v0, 4
   	syscall
   	j exit		#exit
  not0:		#both dividend and divisor != 0
  #separates the fields of the 32-bit binary code
    #field Sign: shift right both dividend and divisor by 31 bit. 
    	srl $t1, $a1, 31		#truong sign cua divident = $t1
    	srl $t2, $a2, 31		#truong sign cua divisor = $t2
    #field Exponent: shift left both dividend and divisor by 1 bit,  then shift right by 24 bit to take 8 bit of Exponent
      #field Exponent of dividend
     	sll $t3, $a1, 1 		
	srl $t3, $t3, 24
	subi $t3, $t3, 127	#Exponent dividend = $t3
      #field Exponent of divisor
	sll $t4, $a2, 1 			
	srl $t4, $t4, 24
	subi $t4, $t4, 127	#Exponent divisor = $t4
    #field Fraction: #shift left both dividend and divisor by 9 bit then shift right by 9 bit to take 23 bit of Fraction
    		      #then add with 0x00800000 in order to assign 24th bit both dividend and divisor = 1
      #field Fraction of dividend
	sll $t5, $a1, 9		
	srl $t5, $t5, 9
	ori $t5, $t5, 0x00800000	#$t5 = 1bit + fraction dividend
      #field fraction of divisor
	sll $t6, $a2, 9		
	srl $t6, $t6, 9
	ori $t6, $t6, 0x00800000	#$t6 = 1bit + fraction divisor
	
   #Calculate
   	xor $t1, $t1, $t2		#field sign of quotient = $t1
   	sub $t2, $t3, $t4		#Exponent of quotient = $t2
   	addu $t2, $t2, 127
   	
   	slt $s0, $t5, $t6		#check (1 + Fraction dividend)/(1 + Fraction divisor) < 1 ?
   	li $t9, 0x00800000	#assign 23th bit of t9 = 1,  another = 0 ?? calculate
   	li $t8, 24		# t8 = 24,  lay 24 bit
   	li $t3, 0		# t3 = 0,  save fraction
   loop:
   	div $t5, $t6		#Fraction cua quotient = $t3 = (1 + Fraction dividend)/(1 + Fraction divisor) - 1
   	mflo $t7		#Quotient
   	mfhi $t5		#Remainder
   	mulu $t7, $t7, $t9
   	addu $t3, $t3, $t7
   	srl $t9, $t9, 1
   	sll $t5, $t5, 1
   	subu $t8, $t8, 1
   	beqz $t5, endloop	#t5 = 0 mean remainder = 0
   	beqz $t8, endloop	#t8 = 0 tuc da lay du 24 bit
   	j loop
   endloop:
   	beqz $s0,  notsubtract	#s0 = 0 tuc fraction cua dividend nho hon fraction cua divisor
   	sll $t3, $t3, 1		#shift left 1 bit
   	subi $t2, $t2, 1		#subtract Exponent by 1 bit
   notsubtract:
   	andi $t3, $t3, 0x007FFFFF	#thuc hien and de khu di bit 1 o bit thu 23
   	
   #combined fields and save in $t4
   	sll $t4, $t1, 31		#combined fields
   	sll $t2, $t2, 23		#combined Exponent
   	or $t4, $t4, $t2
   	or $t4, $t4, $t3		#combined Fraction
   #Check remainder = 0
   	sll $t5, $t5, 1
   	slt $t5, $t6, $t5
   	beqz $t5,  remainder0
   	addi $t4, $t4, 1		#if remainder != 0, add by 1 bit to round
   	remainder0:
   #chuyen du lieu sang float
   	mtc1 $t4, $f12
   
#Xuat ket qua
   	la $a0, Nhac_quotient
   	li $v0, 4
   	syscall
   
   	li $v0, 2
   	syscall
#Ket thuc chuong trinh (syscall)
exit:
	li $v0, 10
	syscall