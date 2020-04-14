# ------------------------------------------- 
#	Autor: Micha³ Oracki 304099	      
#	Grupa: 107			      
#	Temat: Czytnik kodów EAN-8	      
#	Data: 13.04.2020		      	     
#	Obs³ugiwany format: BMP mono-chrome   
# ------------------------------------------- 
	
.eqv	headeraddr 0
.eqv    filesize   4
.eqv	imgaddr    8
.eqv	imgwidth   12
.eqv    imgheight  16


	.data
error_msg:	.asciiz "An error occured during decoding (Invalid EAN-8 code or bmp file opened with errors)"
success_msg:	.asciiz "EAN-8 code: "
code:	.space 16
imgdescriptor:	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

# kody Start/Stop i kod modu³u rozdzielaj¹cego	
start_sign:	.word 5
divider_sign:	.word 10
stop_sign:	.word 5

# kody cyfr w L i R code (od 0 do 9) 
left_codes: 	.word 13, 25, 19, 61, 35, 49, 47, 59, 55, 11
right_codes:	.word 114, 102, 108, 66, 92, 78, 80, 68, 72, 116

img:	.space 	32768
fname:	.asciiz "5px_99999919.bmp"

	.text
main:
	jal open_file
	move $a0, $v0		# przeniesienie deskryptora pliku do $a0
	la $a1, img		# adres nazwy pliku do odczytania
	
	jal read_bmp
	lw $a1, imgheight($a0)  # pobranie wysokosci pliku
	li $a0, 0		# ustalenie koordynatu x
	jal get_middle_pixel	# ustalenie srodkowego wiersza obrazku
margin:
	jal left_margin		# w $s1 ilosc pikseli marginesu
	srl $t4, $s1, 3		# dzielenie calkowite przez 8 - przesuniecie adresu
	and $t3, $s1, 7		# dzielenie z reszta przez 8 - przesuniecie bitu
	
bar:
	la $a0, ($t0)		# zaladowanie adresu 1 bajtu
	addu $a0, $a0, $t4 	# dodanie przesuniecia adresu
	li $a1, 0		# numer bitu do odczytania
	addu $a1, $a1, $t3	# dodanie przesuniecia bitu
	li $s1, 0		# licznik bitow - liczy szerokosc paska
bar_width:
	jal get_bit
	bne $v0, 0, prepare_for_start
	addiu $a1, $a1, 1
	addiu $s1, $s1, 1
	beq $a1, 8, inc_byte
	j bar_width
inc_byte:
	addiu $a0, $a0, 1	# zinkrementowanie adresu bajtu
	li $a1, 0		# zerowanie numeru bitu do odczytania
	j bar_width
	
prepare_for_start:
	la $t9, code		# zapisanie adresu kodu wyjœciowego
	la $a0, ($t0)		# ustawienie adresu na pcozatek wiersza
	addu $a0, $a0, $t4	# dodanie przesuniecia adresu
	li $a1, 0		# zerowanie numeru bitu do odczytania
	addu $a1, $a1, $t3	# dodanie przesuniecia bitu
	li $s2, 0		# licznik przeczytanych bitów
	li $t2, 3		# szerokosc modulu startu
start_loop:
	jal get_bit
	jal load_bit
	beq $v1, 1, compare_s	# sprawdzenie, czy skonczono czytanie modulu ($v1 flaga konca)
	jal balance_byte_offset
	j start_loop
compare_s:
	lw $t8, start_sign
	move $t4, $t2		# szerokosc modulu
	jal compare_sign	

prepare_for_left:
	jal balance_byte_offset
	li $s0, 0		# zerowanie rejestru kodow	
	li $s2, 0		# zerowanie licznika przeczytanych bitow
	li $t2, 28		# ilosc paskow w segmencie cyfr
left_loop:
	jal get_bit
	jal load_bit
	beq $v1, 1, decode_left	# sprawdzenie, czy skonczono czytanie modulu ($v1 flaga konca)
	jal balance_byte_offset
	j left_loop
decode_left:
	li $t4, 0		# wybranie opcji dekodowania kodów L
	jal decode
	
prepare_for_mid:
	jal balance_byte_offset
	li $s0, 0			
	li $s2, 0
	li $t2, 5
mid_loop:
	jal get_bit
	jal load_bit
	beq $v1, 1, compare_m	# sprawdzenie, czy skonczono czytanie modulu ($v1 flaga konca)
	jal balance_byte_offset
	j mid_loop
compare_m:
	lw $t8, divider_sign
	move $t4, $t2		# szeroksoc modulu 
	jal compare_sign
	
prepare_for_right:
	jal balance_byte_offset
	li $s0, 0			
	li $s2, 0
	li $t2, 28
right_loop:
	jal get_bit
	jal load_bit
	beq $v1, 1, decode_right	# sprawdzenie, czy skonczono czytanie modulu ($v1 flaga konca)
	jal balance_byte_offset
	j right_loop
decode_right:
	li $t4, 1		# wybranie opcji dekodowania kodów R
	jal decode
	
prepare_for_stop:
	jal balance_byte_offset
	li $a1, 0		# zerowanie numeru bitu do odczytania
	li $s2, 0		# licznik przeczytanych bitów
	li $t2, 3		# szerokosc modulu stop
stop_loop:
	jal get_bit
	jal load_bit
	beq $v1, 1, compare_st	# sprawdzenie, czy skonczono czytanie modulu ($v1 flaga konca)
	jal balance_byte_offset
	j stop_loop
compare_st:
	lw $t8, stop_sign
	move $t4, $t2		# szerokosc modulu
	jal compare_sign
		
success_exit:
	la $a0, success_msg
	li $v0, 4
	syscall
	la $a0, code		# za³adowanie odczytanego kodu
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

open_file:
	la $a0, fname
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	bltz $v0, error_exit	# sprawdzenie poprawnosci otworzenia pliku
	jr $ra

read_bmp:
	# $a0 - adres deskryptora obrazu
	# $a1 - adres nazwy pliku do odczytania
	# $v0 - informacja o bledze ($v0 < 0, wpp. sukces) 

	li $a2, 32768
	li $v0, 14
	syscall
	ble $v0, 0, error_exit	# jezeli blad podczas czytania, to przechodzi do etytkiety z wiadomoscia bledu
	move $t0, $v0
	li $v0, 16
	syscall
	
	la $a0, imgdescriptor
	sw $t0, filesize($a0)
	sw $a1, headeraddr($a0)
	lhu $t0, 10($a1) 	# przesuniêcie obrazu wzg poczatku pliku
	addu $t1, $a1, $t0 	# adres obrazu
	sw $t1, imgaddr($a0) 	# imgdescriptor->imgaddr = $t1
	lhu $t0, 18($a1)     	# szerokosc obrazu w pikselach
	sw $t0, imgwidth($a0) 
	lhu $t0, 22($a1)     	# wysokosc obrazu w pikselach
	sw $t0, imgheight($a0) 
	
	lw $a2, imgwidth($a0)
	addiu $a2, $a2, 31
	srl $a2, $a2, 5
	sll $a2, $a2, 2		# obliczenie szeroksoci obrazu w bajtach

	lw $t0, imgaddr($a0)	# W $t0 znajduje sie adres pierwszego piksela
	
	jr $ra
	

get_middle_pixel:
	# $a0 - wartosc koordynatu x
	# $a1 - wysokosc obrazu
	# $a2 - szeroksoc w bajtach
	# $t0 - adres pierwszego piksela
	
	srl $t1, $a1, 1		# adres koordynatu y (polowa wysokosci)
	
	mul $t5, $t1, $a2  	# $t5= y*szerokosc_w_bajtach
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	# $t3= 3*x
	add $t5, $t5, $t3	# $t5 = 3x + y * szerokosc_w_bajtach
	add $t2, $t2, $t5	# adres piksela 
	
	jr $ra


get_bit:
	# W $a0 adres bajtu, w którym znajduje siê bit
	# W $a1 numer bitu, który ma odczytaæ
	# W $v0 funkcja zwraca wartoœæ bitu
	li $a3, 1
	li $s3, 7
	subu $s3, $s3, $a1	# wylcizenie przesuniecia maski
	sllv $a3, $a3, $s3	# przesuniecie maski
	lbu $v0, ($a0)		
	and $v0, $v0, $a3
	srlv $v0, $v0, $s3	# przesuniecie bitow w prawo
	jr $ra

	
balance_byte_offset:
	# $s1 - szerokosc paska
	# $a0 - adres aktualnego bajtu
	# $a1 - numer bitu do odczytania
	addu $a1, $a1, $s1
	blt $a1, 8, return
	addiu $a1, $a1,  -8
	addiu $a0, $a0, 1
return:
	jr $ra


load_bit:
	# $v0 - wartosc bitu
	# $s2 - licznik przeczytanych bitow
	# $s0 - aktualna wartosc kodu
	# $t2 - ilosc bitow do przeczytania
	# $v1 - flaga konca sprawdzania (1 = true, 0 = false)
	li $v1, 0
	sll $s0, $s0, 1
	addu $s0, $s0, $v0
	addiu $s2, $s2, 1
	beq $s2, $t2, flag
	jr $ra
flag:
	li $v1, 1
	jr $ra


decode:
	# $t4 - Wybor dekodowania L lub R (dla L $t4 = 0)
	li $t1, 127 		# maska o dlugosci 7 jedynek	
	not $s0, $s0		# negacja znakow do odczytania kodow
	li $t2, 21		# liczba miejsc do przesuniecia w prawo
	sllv $t1, $t1, $t2
decode_loop:
	beq $t2, -7, return_decode
	move $s4, $s0		
	and $s4, $s4, $t1	
	srlv $s4, $s4, $t2	# wybieranie modulu (7 bitów)
	addiu $t2, $t2, -7	# zmniejszanie przesuniecia w prawo
	li $t6, 0		# indeks
	li $t7, 0		# licznik
	beq $t4, 0, compare_l
compare_r:
	lw $t8, right_codes($t6)
	beq $s4, $t8, to_str
	addiu $t7, $t7, 1
	addiu $t6, $t6, 4
	bge $t7, 10, error_exit
	j compare_r
compare_l:
	lw $t8, left_codes($t6)
	beq $s4, $t8, to_str
	addiu $t7, $t7, 1
	addiu $t6, $t6, 4
	bge $t7, 10, error_exit
	j compare_l
to_str:
	# $t7 - licznik do przechodzenia po liscie cyfr
	# $t9 - string z kodem
	li $t3, '0'
	addu $t3, $t3, $t7
	sb $t3, ($t9)
	addiu $t9, $t9, 1
	srl $t1, $t1, 7
	j decode_loop
return_decode:
	jr $ra
	
compare_sign:
	# $t4 - dlugosc modulu znaku
	# $t8 - wartosc prawidlowa znaku
	li $t3, 32 		# szerokosc rejestru
	subu $t3, $t3, $t4
	move $s4, $s0
	not $s4, $s4
	sllv $s4, $s4, $t3	# wyciagniecie z rejestru bitow od prawej strony
	srlv $s4, $s4, $t3
	bne $s4, $t8, error_exit
	jr $ra
	
left_margin:
	la $a0, ($t0)		# zaladowanie adresu 1 bajtu
	li $a1, 0		# numer bitu do odczytania
	li $s1, 0		# licznik bitow - liczy szerokosc marginesu
	
left_margin_width:
	li $a3, 1
	li $s3, 7
	subu $s3, $s3, $a1	# wylcizenie przesuniecia maski
	sllv $a3, $a3, $s3	# przesuniecie maski
	lbu $v0, ($a0)		
	and $v0, $v0, $a3
	srlv $v0, $v0, $s3
	bne $v0, 1, end
	addiu $a1, $a1, 1
	addiu $s1, $s1, 1
	beq $a1, 8, inc_byte_m
	j left_margin_width
inc_byte_m:
	addiu $a0, $a0, 1	# zinkrementowanie adresu bajtu
	li $a1, 0		# zerowanie numeru bitu do odczytania
	j left_margin_width
end:
	jr $ra
