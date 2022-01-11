#the eliza program takes in a 100 character input from the user. Eliza creates a personalized reponse to sentences matching one
#of the following four sentence patterns: "I am __", "my __ me", "you __ me", and "am I __". For other sentences, Eliza provides a 
#general response: "in what way?" This program simulates a conversation between the user and the computer, allowing
#the conversation to continue until the user decides to leave.
	.data
tmay:		.asciiz "tell me about your "
enter:		.asciiz "\n"
enterb:		.byte	'\n'
iasthya:	.asciiz "I am sorry to hear you are "
dybya:		.asciiz "Do you believe you are "
qm:		.byte '?'
wdyti:		.asciiz "Why do you think i "
y:		.asciiz "you?"
iww:		.asciiz "in what way?"
goodbye:	.asciiz "\n goodbye!"
welcome:	.asciiz "Welcome to eliza. In 100 characters or less, what seems to be the problem? \n"
userInput:	.byte	0:101	#number of bytes allocated for user response
wordtracker:	.word	-1:100	#this array will log the positions of the beginning of each word
alphabet:	.byte	'a','e','i','m','o','u','y',' '	
is:		.byte	'i',0
ams:		.byte	'a','m',0
mys:		.byte	'm','y',0
mes:		.byte	'm','e',0
yous:		.byte	'y','o','u',0


	.text

	la	$a0, welcome	#load welcome message
	li	$v0,4		#print message	
	syscall			#exeute
eliza:	li	$v0,8		#prepare to read in a string
	la	$a0, userInput	#load address of buffer into a0
	li	$a1, 101	#size of string to read in is same as buffer size
	syscall			#execute
	lb	$t0,0($a0)	#t0 = s0(0)
	lb	$t1,enterb	#$t1 = '\n'
	beq	$t0,$t1,exit	#if the user just presses enter, exit
	jal	parse		#jump to parse
	j	eliza		#once you get back, jump to the start
	
#the parse function fills the wordtracker array with the index of the char at the 
#beginning of each word in the user input. For the last word, it stores the index of where the
#word ends +1.
parse:	addi	$sp,$sp,-16	#adjust stack for the three vars
	sw	$s0,0($sp)	#store current s0 to the stack
	sw	$s1,4($sp)	#store current s1 to the stack
	sw	$ra,8($sp)	#store current return address to the stack
	sw	$s7,12($sp)	#store current s7 to the stack
	jal	lower		#make the string lowercase
	li	$s0,0		#s2 will track location in userInput (increment by 1)
	li	$s1,0		#s3 will track location in wordtracker(increment by 4)
	lb	$t2,userInput($s0)	#temporarilly loads first byte of ui into t2 to check if its a space
	bne	$t2,' ',check1		#if the first value isn't a space, store it before continuing
fillwt:	lb	$t2,userInput($s0)	#$t2 = userInput[s0]
	beq	$t2,$zero,exitf	#when you've hit the end of the userInput, exit
	beq	$t2,' ',fill	#when userInput[t2] = " ", fill
	addi	$s0,$s0,1	#increment s2
return:	j	fillwt		#jump back up
fill:	addi	$s0,$s0,1	#increment t0 to the char right after space
	lb	$t1,userInput($s0)	#load byte into t1 temporarily
	beq	$s7,$t1,fill	#if you hit a space(two spaces in a row!) look at next char
	sw	$s0,wordtracker($s1)	#store t0 into wordtracker[s3], where t0 is the index of beginning of word
	addi	$s1,$s1,4	#increment s3 to the next word
	j	return		#jump back up to the return
check1:	sw	$s0,wordtracker($s1)	#store t2 into wordtracker[s3]
	addi	$s1,$s1,4	#increment s2 to the next word
	j	fillwt		#jump back up to the wordtracker
exitf:	lw	$s0,0($sp)	#restore s0
	lw	$s1,4($sp)	#restore s1
	lw	$ra,8($sp)	#retore return address
	lw	$s7,12($sp)	#restore s7
	addi	$sp,$sp,16	#adjust the stack
	jal	patternmatch	#check outgoing values
	jr	$ra		#when the method returns, go back to start
	

#the lower function goes over the user input and takes out any non-alphanumeric chars, with the exception
#of some punctiation. It also makes the alphabet characters lowercase. I got help from stack exchange
#with this method (https://stackoverflow.com/questions/43416771/mips-lower-to-uppercase).
lower:		addi	$sp,$sp,-12	#adjust stack
		sw	$s0,0($sp)	#store s0
		sw	$s1,4($sp)	#store s1
		sw	$ra,8($sp)	#store ra
		li	$s0,0		#s0 = 0
lowerloop:	lb	$s1,userInput($s0)	#s1 gets char in userinput
		beq	$s1,$0,lowerleave	#when you've adjusted the string, leave
		blt	$s1,'a',makelower	#if the char value is uppercase, make it lower
lowerreturn:	addi	$s0,$s0,1		#increment
		j	lowerloop		#loop back up
makelower:	beq	$s1,' ',lowerreturn	#don't change spaces
		beq	$s1,'\'',lowerreturn	#don't change apostrophes
		beq	$s1,'-',lowerreturn	#dont change dashes
		slti	$t0,$s1,0x3A		#if the char < 0x40, t0 = 1
		li	$t2,0x2F		#t2 = 0x29
		sgt	$t1,$s1,$t2		#if the char > 0x29, t1=1
		add	$t0,$t0,$t1		#t0 = t0+t1
		li	$t2,2			#t2 = 2
		beq	$t0,$t2,lowerreturn	#if t0 is an integer, don't replace
		slti	$t0,$s1,0x5B		#if the char < 0x5B(Z+1), t0 = 1
		li	$t2,0x40		#t2 = 0x40
		sgt	$t1,$s1,$t2		#if the char > 0x40(A-1), t1=1
		add	$t0,$t0,$t1		#t0 = t0+t1
		li	$t2,2			#t2 = 2
		beq	$t0,$t2,upper		#if t0 is an uppercase, make lower
		j	fixer			#fix it
upper:		addi	$s1,$s1,0x20		#20 is the hex. dif between any upper and lowercase letter
		j	together 		#jump to put the new value in
fixer:		li	$t2,7
		lb	$s1,alphabet($t2)	#make s1 a space if it is punctuation
together:	sb	$s1,userInput($s0)	#store the lowercase byte
		j	lowerreturn		#continue
lowerleave:	lw	$s0,0($sp)		#restore s0
		lw	$s1,4($sp)		#restore s1
		sw	$ra,8($sp)		#restore ra
		addi	$sp,$sp,8		#readjust stack
		jr	$ra			#return
		
		
	
#the patternmatch function determines which pattern the user input matches.
patternmatch:	addi	$sp,$sp,-20		#adjust stack
		sw	$a0,0($sp)		#save current a0 to stack
		sw	$a1,4($sp)		#save current a1 to stack
		sw	$s0,8($sp)		#save current s0 to stack
		sw	$s1,12($sp)		#save current s1 to stack
		sw	$s2,16($sp)		#save current s2 to stack
		li	$s0,0			#s0 will be wordtracker(s0)
pmloop:		lw	$s1,wordtracker($s0)	#s1 gets the index of beginning of word in UI
		move	$a2,$s0			#load s0 into argument 2
		la	$t0,userInput		#load userinput into t0
		add	$s2,$s1,$t0		#s2 gets the address of where that word begins
		move	$a0,$s2			#load s2 into argument 0
		la	$a1,is			#load address 2 into argument 1
		jal	streq			#go to check if the strings are equal
		bgtz	$v0,iam		#if v0=1, then the word = my. go check that pattern
pmreturn1:	la	$a1,ams			#load address 2 into argument 1
		jal	streq			#go to check if the strings are equal
		bgtz	$v0,ami			#if v0=1, then the word = i. go check that pattern
pmreturn2:	la	$a1,mys			#load address 2 into argument 1
		jal	streq			#go to check if the strings are equal
		bgtz	$v0,my			#if v0=1, then the word = am. go check that pattern
pmreturn3:	la	$a1,yous		#load address 2 into argument 1
		jal	streq			#go to check if the strings are equal
		bgtz	$v0,you		#if v0=1, then the word = you. go check that pattern
pmreturn4:	bltz	$s1,inwhatway		#if s1 = -1, then you've reached the final word. print default.
		addi	$s0,$s0,4		#increment to the next word
		j	pmloop			#loop up
		
#the inwhatway function handles the base case in which no other pattern is matched.
inwhatway: 	la	$a0,iww			#ao = "in what way?"
		li	$v0,4			#prepare to print string
		syscall				#execute
		li	$v0,4			#prepare to print
		la	$a0,enter		#load enter key into a0
		syscall				#execute
		j	clear			#call clear function

#the iam function checks to see if the pattern matches "i am". If so, it prints the 
#correct response. If not, it jumps back to continue the search. It takes in the current index in wordtracker
#in arg. field a2 (a0 and a1 are being used by other vars for other methods)
iam:		addi	$sp,$sp,-24		#adjust stack
		sw	$ra,0($sp)		#store current ra
		sw	$a0,4($sp)		#store current a0
		sw	$a1,4($sp)		#store current a1
		sw	$a2,8($sp)		#store current a2
		sw	$s0,12($sp)		#store current s0
		sw	$s1,16($sp)		#store current s1
		sw	$s2,20($sp)		#store current s2
		move	$s0,$a2			#s0 takes in the current index in wordtracker
		addi	$s0,$s0,4		#increment to next word, as we know this word was i
		lw	$s1,wordtracker($s0)	#s1 gets index of current word
		la	$a0,userInput($s1)	#a0 gets address of the current word
		la	$a1,ams			#a1 gets "am"
		jal	streq			#check to see if the next word is am
		bgtz	$v0,iambreak		#if the word was am, then it matches the pattern. continue
		lw	$ra,0($sp)		#restore current ra
		lw	$a0,4($sp)		#restore current a0
		lw	$a1,4($sp)		#restore current a1
		lw	$a2,8($sp)		#restore current a2
		lw	$s0,12($sp)		#restore current s0
		lw	$s1,16($sp)		#restore current s1
		lw	$s2,20($sp)		#restore current s2
		addi	$sp,$sp,24		#readjust stack
		j	pmreturn1		#jump to check next pattern
iambreak:	la	$a0,iasthya		#load string into a0
		li	$v0,4			#prepare to print string
		syscall				#execute
		addi	$s0,$s0,4		#go to word after am
		lw	$s1,wordtracker($s0)	#s1 gets index of beginning of next word
iamloop:	lb	$t0,userInput($s1)	#load current byte into t0
		beq	$t0,$0,iamleaving	#once you reach the end of user input, leave
		move	$a0,$t0			#load byte into a0
		li	$v0,11			#prepare to print char
		syscall				#syscall
		addi	$s1,$s1,1		#increment s1
		j	iamloop			#jump back up
iamleaving:	la	$a0,enter		#load string into a0
		li	$v0,4			#prepare to print string
		syscall				#execute
		lw	$ra,0($sp)		#restore current ra
		lw	$a0,4($sp)		#restore current a0
		lw	$a1,4($sp)		#restore current a1
		lw	$a2,8($sp)		#restore current a2
		lw	$s0,12($sp)		#restore current s0
		lw	$s1,16($sp)		#restore current s1
		lw	$s2,20($sp)		#restore current s2
		addi	$sp,$sp,24		#readjust stack
		j	clear			#clear to start over	
		
			




#the ami function checks to see if the pattern matches "am i". If so, it prints the correct 
#response. If not, it jumps back to continue the search.
ami:		addi	$sp,$sp,-24		#adjust stack
		sw	$ra,0($sp)		#store current ra
		sw	$a0,4($sp)		#store current a0
		sw	$a1,4($sp)		#store current a1
		sw	$a2,8($sp)		#store current a2
		sw	$s0,12($sp)		#store current s0
		sw	$s1,16($sp)		#store current s1
		sw	$s2,20($sp)		#store current s2
		move	$s0,$a2			#s0 takes in the current index in wordtracker
		addi	$s0,$s0,4		#increment to next word, as we know this word was am
		lw	$s1,wordtracker($s0)	#s1 gets index of current word
		la	$a0,userInput($s1)	#a0 gets address of the current word
		la	$a1,is			#aa1 gets "i"
		jal	streq			#check to see if the next word is am
		bgtz	$v0,amibreak		#if the word was am, then it matches the pattern. continue
		lw	$ra,0($sp)		#restore current ra
		lw	$a0,4($sp)		#restore current a0
		lw	$a1,4($sp)		#restore current a1
		lw	$a2,8($sp)		#restore current a2
		lw	$s0,12($sp)		#restore current s0
		lw	$s1,16($sp)		#restore current s1
		lw	$s2,20($sp)		#restore current s2
		addi	$sp,$sp,24		#readjust stack
		j	pmreturn2		#freturn to check other patterns
amibreak:	la	$a0,dybya		#load string into a0
		li	$v0,4			#prepare to print string
		syscall				#execute
		addi	$s0,$s0,4		#go to word after am
		lw	$s1,wordtracker($s0)	#s1 gets index of beginning of next word
amiloop:	lb	$t0,userInput($s1)	#load current byte into t0
		beq	$t0,$0,amileaving	#once you reach the end of user input, leave
		move	$a0,$t0			#load byte into a0
		li	$v0,11			#prepare to print char
		syscall				#syscall
		addi	$s1,$s1,1		#increment s1
		j	amiloop			#jump back up
amileaving:	lb	$a0,qm		#load string into a0
		li	$v0,11			#prepare to print string
		syscall	
		la	$a0,enter		#load string into a0
		li	$v0,4			#prepare to print string
		syscall				#execute
		lw	$ra,0($sp)		#restore current ra
		lw	$a0,4($sp)		#restore current a0
		lw	$a1,4($sp)		#restore current a1
		lw	$a2,8($sp)		#restore current a2
		lw	$s0,12($sp)		#restore current s0
		lw	$s1,16($sp)		#restore current s1
		lw	$s2,20($sp)		#restore current s2
		addi	$sp,$sp,24		#readjust stack
		j	clear			#reset 
			
#the my function check to see if the pattern matches "my me". If so, it prints the correct 
#response. If not, it returns to the pattern checker. It takes in the current index of wordtracker in a2 
my:		addi	$sp,$sp,-16	#adjust stack
		sw	$ra,0($sp)	#store ra
		sw	$a0,4($sp)	#store a0
		sw	$s0,8($sp)	#store s0
		sw	$s1,12($sp)	#store s1
		addi	$s0,$a2,4	#we know the passed-in word was "my". go to the next one
		move	$a0,$s0		#load as an argument
		jal	me		#check to see if the rest of the string contains me
		bltz	$v0,myneq	#if v0=-1, the word didn't contain me. 
		move	$t0,$v0		#save position that "me" started in
		lw	$t1,wordtracker($t0)	#index of me
		la	$t7,userInput($t1)	#get address of beginning of me
		la	$a0,tmay	#load string
		li	$v0,4		#prepare to print
		syscall			#execute
		lw	$s1,wordtracker($s0)	#s1 holds index of next word
		la	$t1,userInput($s1)	#get address of next word
		beq	$t1,$t7,mybreak		#if the address is "me", we don't want to print it
myloop:		lb	$t1,userInput($s1)	#t0 holds the next char
		beq	$t1,' ',mybreak		#once you've reached a space, leave
		move	$a0,$t1			#move byte into a0
		li	$v0,11			#prepare to print byte
		syscall				#execute
		addi	$s1,$s1,1		#increment s1
		j	myloop			#loop up
myneq:		lw	$ra,0($sp)	#restore ra
		lw	$a0,4($sp)	#restore a0
		lw	$s0,8($sp)	#restore s0
		lw	$s1,12($sp)	#restore s1
		addi	$sp,$sp,12	#readjust stack
		j	pmreturn3	#if the string doesn't contain "me", return to patternmatch
					#so we can just jump to the base case.
mybreak:	la	$a0,enter		#prepare string
		li	$v0,4			#prepare to print string
		syscall				#execute
		lw	$ra,0($sp)	#restore ra
		lw	$a0,4($sp)	#restore a0
		lw	$s0,8($sp)	#restore s0
		lw	$s1,12($sp)	#restore s1
		addi	$sp,$sp,12	#readjust stack
		j	clear		#jump to clear
				

#the you function checks to see if the pattern matches "you me". If so, it prints the
#correct response. If not, it jumps back to continue the search. It takes in the index of wordtracker at a2.
you:		addi	$sp,$sp,-16	#adjust stack
		sw	$ra,0($sp)	#store ra
		sw	$a0,4($sp)	#store a0
		sw	$s0,8($sp)	#store s0
		sw	$s1,12($sp)	#store s1
		addi	$s0,$a2,4	#we know the passed-in word was "my". go to the next one
		move	$a0,$s0		#load as an argument
		jal	me		#check to see if the rest of the string contains me
		bltz	$v0,youneq	#if v0=-1, the word didn't contain me. 
		move	$t0,$v0		#v0 returns the location of the beginning of the word "me"
		lw	$t1,wordtracker($t0)	#t1 gets the location of the 'm' char in userinput
		la	$s2,userInput($t1)	#s2 gets that address
		la	$a0,wdyti	#load string
		li	$v0,4		#prepare to print
		syscall			#execute
		lw	$s1,wordtracker($s0)	#s1 holds index of next word
youloop:	lb	$t1,userInput($s1)	#t1 holds the next char
		la	$t2,userInput($s1)	#t2 holds the address of the byte
		beq	$s2,$t2,youbreak		#once you've reached the beginning of me, leave
		move	$a0,$t1			#move byte into a0
		li	$v0,11			#prepare to print byte
		syscall				#execute
		addi	$s1,$s1,1		#increment s1
		j	youloop			#loop up
youneq:		lw	$ra,0($sp)	#restore ra
		lw	$a0,4($sp)	#restore a0
		lw	$s0,8($sp)	#restore s0
		lw	$s1,12($sp)	#restore s1
		addi	$sp,$sp,12	#readjust stack
		j	pmreturn4	#if the string doesn't contain "me", return to patternmatch
					#so we can just jump to the base case.
youbreak:	la	$a0,y		#load string
		li	$v0,4		#prepare to print
		syscall			#execute
		la	$a0,enter		#prepare string
		li	$v0,4			#prepare to print string
		syscall				#execute
		lw	$ra,0($sp)	#restore ra
		lw	$a0,4($sp)	#restore a0
		lw	$s0,8($sp)	#restore s0
		lw	$s1,12($sp)	#restore s1
		addi	$sp,$sp,12	#readjust stack
		j	clear		#jump to clear	


#the me function is called by "my" and "you" to see if the rest of the user response contains 
#the word "me". If it does, it returns the index of where the word "me" starts in v0. Otherwise,
#it returns -1. This function takes in the current index of wordtracker in $a0
me:		addi	$sp,$sp,-20		#adjust the stack
		sw	$ra,0($sp)		#store ra
		sw	$a0,4($sp)		#store a0
		sw	$a1,8($sp)		#store a1
		sw	$s0,12($sp)		#store s0
		sw	$s1,16($sp)		#store s1
		move	$s0,$a0			#s0 is the index of wordtracker
meloop:		lw	$s1,wordtracker($s0)	#s1 gets loc. for the next word of userInput
		bltz	$s1,meneq		#if you get to s1 = -1, there was no "me" in the userInput.
		la	$a0,userInput($s1)	#argument 0 is the address of the first word
		la	$a1,mes			#a1 = "me" address
		jal	streq			#check to see if the word is "me"
		bgtz	$v0,meyes		#if v0 = 1, is was a match. return
		addi	$s0,$s0,4		#increment s0
		j	meloop			#jump back up
meneq:		li	$v0,-1			#there was no match.
		lw	$ra,0($sp)		#restore ra
		lw	$a0,4($sp)		#restore a0
		lw	$a1,8($sp)		#restore a1
		lw	$s0,12($sp)		#restore s0
		lw	$s1,16($sp)		#restore s1
		addi	$sp,$sp,20		#readjust stack
		jr	$ra			#return
meyes:		move	$v0,$s0			#v0 gets where s0 started
		lw	$ra,0($sp)		#restore ra
		lw	$a0,4($sp)		#restore a0
		lw	$a1,8($sp)		#restore a1
		lw	$s0,12($sp)		#restore s0
		lw	$s1,16($sp)		#restore s1
		addi	$sp,$sp,20		#readjust stack
		jr	$ra			#return		



#the strlen method takes in the beginning address of a string and returns the length of the string in v0.
strlen:		addi	$sp,$sp,-4	#adjust stack
		sw	$s0,0($sp)	#save value for s0
		li	$s0,0		#s0 will be the counter
whilesl:	add	$t2,$s0,$a0	#prepare correct address
		lb	$t1,0($t2)	#load byte at s0(t0) into t1
		beq	$t1,' ',slend	#if you hit a space, you are also at the end of your word
		beq	$t1,$0,slend	#when you reach the end of the string, return
		beq	$t1,'\n',slend	#if the user pressed enter, you are at the end of a string
		addi	$s0,$s0,1	#increment t0
		j	whilesl		#loop up
slend:		move	$v0,$s0		#return value
		lw	$s0,0($sp)	#restore s0	
		addi	$sp,$sp,4	#readjust stack
		jr	$ra		#return to caller

#the streq method takes in the beginning of one string in a0 and the beginning of another in a1. In v0,
#streq returns 1 if the two strings are equal, and -1 if they are not.
streq:		addi	$sp,$sp,-12	#adjust stack
		sw	$ra,0($sp)	#store current ra
		sw	$s0,4($sp)	#store current s0
		sw	$s1,8($sp)	#store current s1
		jal	strlen		#compute strlen for first string
		move	$t0,$v0		#store value in t0
		move	$s0,$a0		#temporarily store a0 address in t7
		move	$a0,$a1		#move second arg to first
		jal	strlen		#compute strlen for second string
		move	$t1,$v0		#store length in t1
		move	$a0,$s0		#restore first argument
		bne	$t0,$t1,neq	#if the strings aren't the same length, instantly branch
		li	$s0,0		#this will track first string
		li	$s1,0		#this will track second string
whilestreq:	add	$t6,$s0,$a0	#load address for first string
		add	$t7,$s1,$a1	#load addres for second string
		lb	$t2,0($t6)	#char of first string
		lb	$t3,0($t7)	#char of second string
		beq	$t3,$0,streqyes	#if you reach the end of the string and all the chars are the same, 
					#they are the same
		beq	$t3,$t7,streqyes	#another way of checking the end of a word, if the ui was put into a1 isntead
		bne	$t2,$t3,neq	#if they aren't equal
		addi	$s0,$s0,1	#increment counter
		addi	$s1,$s1,1	#increment counter
		j 	whilestreq	#jump back up
neq:		li	$v0,-1		#prepare return argument
		lw	$ra,0($sp)	#restore ra
		lw	$s0,4($sp)	#restore  s0
		lw	$s1,8($sp)	#restore  s1
		addi	$sp,$sp,12	#readjust stack
		jr	$ra		#return
streqyes:	li	$v0,1		#prepare return argument
		lw	$ra,0($sp)	#restore ra
		lw	$s0,4($sp)	#restore s0
		lw	$s1,8($sp)	#restore s1
		addi	$sp,$sp,12	#readjust stack
		jr	$ra		#return

#the printint function takes in an array of inegers(or words) whose initial value is -1
#and prints each value in the array that has been filled
printint:	addi	$sp,$sp,-4	#adjust stack for s0
		sw	$s0,0($sp)	#store current s0 before altering it	
		li	$t0,0		#set t0 = 0
		move	$s0, $a0	#if the argument is inputted in $a0, shift it 
whilep:		lw	$t1, wordtracker($t0)	#store the contents of the current spot in the array
		li	$t3,-1		#load -1 in to check to see when you've reached the end
		beq	$t1,$t3,exit	#if you hit a null element, exit
		li	$v0,1		#prepare to print int
		move	$a0,$t1		#load current array spot to be printed
		syscall			#execute
		li	$v0,4		#prepare to print
		la	$a0,enter	#load enter key into a0
		syscall			#execute
		addi	$t0,$t0,4	#increment counter
		j	whilep		#loop up
		
#the print function prints a string until it hits $0. We don't worry about the stack because this function
#will exit the program immediately after printing
print:		li	$s0,0			#s0 = 0
printloop:	lb	$s1,userInput($s0)	#s1 = next char
		beq	$s1,$0,done		#when you hit 0, leave
		move	$a0,$s1			#load char
		li	$v0,11			#prepare to print char
		syscall				#execute
		addi	$s0,$s0,1		#increment
		j	printloop		#jump up	
done:		j	exit			#leave
		
		

#the clear function clears the wordtracker array and the userInput array before jumping up 
#to the top for the next user input.
clear:		addi	$sp,$sp,-12	#adjust stack
		sw	$s0,0($sp)	#store s0
		sw	$s1,4($sp)	#store s1
		sw	$s2,8($sp)	#store s2
		li	$t0,-1		#t0 = -1
		li	$s0,0		#s0 will track through wordtracker
		li	$s1,0		#s1 will track through userInput
clearwt:	lw	$s2,wordtracker($s0)	#s2 gets the elem. of wordtracker
		beq	$s2,$t0,clearui		#once you hit a -1, go through and clear userinput
		sw	$t0,wordtracker($s0)	#wordtracker(s0) = -1
		addi	$s0,$s0,4		#increment s0
		j	clearwt		#loop up
clearui:	lb	$s2,userInput($s1)	#s2 gets the elem. of userInput
		beq	$s2,$0,clearbreak	#when you reach the last of the inputted values
		sb	$0,userInput($s1)	#userInput(s1) = 0
		addi	$s1,$s1,1		#increment
		j	clearui		#loop up
clearbreak:	lw	$s0,0($sp)	#restore s0
		lw	$s1,4($sp)	#restore s1
		lw	$s2,8($sp)	#restore s2
		addi	$sp,$sp,12	#reset stack
		j	eliza		#jump back to the top	


		
#the exit function is a quick, clean, exit		
exit:	li	$v0,4		#prepare to print
	la	$a0,goodbye	#load goodbye message into a0
	syscall			#execute
	li	$v0, 10		#exits cleanly
	syscall			#execute
	
