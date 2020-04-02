.eqv	headeraddr 0
.eqv    filesize   4
.eqv	imgaddr    8
.eqv	imgwidth   12
.eqv    imgheight  16
.eqv    rowsize    20

	.data
error_msg:	.asciiz "An error occured during decoding (Invalid EAN-8 code or bmp file opened with errors)"
success_msg:	.asciiz "EAN-8 code: "
code:	.space 256
imgdescriptor:	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	
start_sign:	.word 5
divider_sign:	.word 10
stop_sign:	.word 5

L_zero:		.word 13
R_zero:		.word 114
L_one:		.word 25
R_one:		.word 102
L_two:		.word 19
R_two:		.word 108
L_three:	.word 61
R_three:	.word 66
L_four:		.word 35
R_four:		.word 92
L_five:		.word 49
R_five:		.word 78
L_six:		.word 47
R_six:		.word 80
L_seven:	.word 59
R_seven:	.word 68
L_eight:	.word 55
R_eight:	.word 72
L_nine:		.word 11
R_nine:		.word 116

img:	.space 	32768
fname:	.asciiz "12345670_bajt.bmp"

	.text
main:
#	la $a0, imgdescriptor
#	la $a1, fname
#	jal read_bmp_file
#	bltz $v0, main_exit
	
# odczyt pliku powinien byc osobna funkcja read_bmp_file
# ktora mozna byloby uzyc w powyzszy sposob

# $a0 - adres deskryptora obrazu
# $a1 - adres nazwy pliku do odczytania
# $v0 - informacja o bledze ($v0 < 0, wpp. sukces)

	la $a0, fname
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	bltz $v0, error_exit
	move $a0, $v0
	la $a1, img
	li $a2, 32768
	li $v0, 14
	syscall
	move $t0, $v0
	li $v0, 16
	syscall
	
	la $a0, imgdescriptor
	sw $t0, filesize($a0)
	sw $a1, headeraddr($a0)
	lhu $t0, 10($a1) # przesuniêcie obrazu wzg poczatku pliku
	addu $t1, $a1, $t0 # adres obrazu
	sw $t1, imgaddr($a0) # imgdescriptor->imgaddr = $t1
	lhu $t0, 18($a1)     # szerokosc obrazu w pikselach
	sw $t0, imgwidth($a0) 
	lhu $t0, 22($a1)     # wysokosc obrazu w pikselach
	sw $t0, imgheight($a0) 
	
	#od tego miejsca pisze sam
	lw $t0, imgaddr($a0)	# Do $t0 wrzucam adres pierwszego pixela
	la $t9, code		# zapisanie adresu kodu
	
	addiu $t0, $t0, 8908	# W $t0 mam adres pierwszego pixela w 132 wierszu
	lbu $t2, ($t0)		# W najmniej znaj¹cym bajcie &t1 jest pierwszy pixel (8 pixeli) kodu
	
	addiu $t1, $t0, 3	# adres ostatnich osmiu pikseli (jednego paska)
	jal set_compare_code
	jal compare_sign	
	
	addiu $t1, $t1, 7	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare
	
	addiu $t1, $t1, 7	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare
	
	addiu $t1, $t1, 7	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare
	
	addiu $t1, $t1, 7	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare
	
	addiu $t1, $t1, 5	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare_sign
	
	addiu $t1, $t1, 7	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare
	
	addiu $t1, $t1, 7	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare
	
	addiu $t1, $t1, 7	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare
	
	addiu $t1, $t1, 7	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare
	
	addiu $t1, $t1, 3	# zaladowanie ilosci paskow ( ilosc * bajty )
	jal set_compare_code
	jal compare_sign
	
	
	
succes_exit:
	sb $zero, ($t9)		# dopisania null terminated 
	la $a0, success_msg
	li $v0, 4
	syscall
	la $a0, code
	li $v0, 4
	syscall
	j main_exit
error_exit:	
	la $a0, error_msg
	li $v0, 4
	syscall
main_exit:	
	li $v0, 10
	syscall
	
	
	
set_compare_code:
	# $t3 - rejestr z chwilowym kodem modu³u
	li $t3, 0	# Zerowanie rejestru z kodem
loop_start:
	sll $t3, $t3, 1
	beq $t2, 255, white	
	addiu $t3, $t3, 1
white:
	addiu $t0, $t0, 1
	lbu $t2, ($t0)
	bne $t0, $t1, loop_start
	jr $ra
	
compare:
	addiu $t9, $t9, 1	# przejscie do nastepnego znaku wyjsciowego kodu

	# sprawdzanie zgodnosci z tabela cyfr
	la $t4, L_zero
	lw $t4, 0($t4) 
	beq $t3, $t4, add_zero
	la $t4, R_zero
	lw $t4, 0($t4) 
	beq $t3, $t4, add_zero
	la $t4, L_one
	lw $t4, 0($t4) 
	beq $t3, $t4, add_one
	la $t4, R_one
	lw $t4, 0($t4) 
	beq $t3, $t4, add_one
	la $t4, L_two
	lw $t4, 0($t4) 
	beq $t3, $t4, add_two
	la $t4, R_two
	lw $t4, 0($t4) 
	beq $t3, $t4, add_two
	la $t4, L_three
	lw $t4, 0($t4) 
	beq $t3, $t4, add_three
	la $t4, R_three
	lw $t4, 0($t4) 
	beq $t3, $t4, add_three
	la $t4, L_four
	lw $t4, 0($t4) 
	beq $t3, $t4, add_four
	la $t4, R_four
	lw $t4, 0($t4) 
	beq $t3, $t4, add_four
	la $t4, L_five
	lw $t4, 0($t4) 
	beq $t3, $t4, add_five
	la $t4, R_five
	lw $t4, 0($t4) 
	beq $t3, $t4, add_five
	la $t4, L_six
	lw $t4, 0($t4) 
	beq $t3, $t4, add_six
	la $t4, R_six
	lw $t4, 0($t4) 
	beq $t3, $t4, add_six
	la $t4, L_seven
	lw $t4, 0($t4) 
	beq $t3, $t4, add_seven
	la $t4, R_seven
	lw $t4, 0($t4) 
	beq $t3, $t4, add_seven
	la $t4, L_eight
	lw $t4, 0($t4) 
	beq $t3, $t4, add_eight
	la $t4, R_eight
	lw $t4, 0($t4) 
	beq $t3, $t4, add_eight
	la $t4, L_nine
	lw $t4, 0($t4) 
	beq $t3, $t4, add_nine
	la $t4, R_nine
	lw $t4, 0($t4) 
	beq $t3, $t4, add_nine
	
	
	j error_exit
	
add_zero:
	li $t5, '0'
	sb $t5, -1($t9)
	jr $ra
add_one:
	li $t5, '1'
	sb $t5, -1($t9)
	jr $ra
add_two:
	li $t5, '2'
	sb $t5, -1($t9)
	jr $ra
add_three:
	li $t5, '3'
	sb $t5, -1($t9)
	jr $ra
add_four:
	li $t5, '4'
	sb $t5, -1($t9)
	jr $ra
add_five:
	li $t5, '5'
	sb $t5, -1($t9)
	jr $ra
add_six:
	li $t5, '6'
	sb $t5, -1($t9)
	jr $ra
add_seven:
	li $t5, '7'
	sb $t5, -1($t9)
	jr $ra
add_eight:
	li $t5, '8'
	sb $t5, -1($t9)
	jr $ra
add_nine:
	li $t5, '9'
	sb $t5, -1($t9)
	jr $ra
	
compare_sign:
	
	la $t4, start_sign
	lw $t4, 0($t4)
	beq $t3, $t4, continue
	la $t4, stop_sign
	lw $t4, 0($t4)
	beq $t3, $t4, continue
	la $t4, divider_sign
	lw $t4, 0($t4)
	beq $t3, $t4, continue
	
	j error_exit
	
continue:
	jr $ra
	