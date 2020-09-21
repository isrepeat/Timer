.include "IF_STATEMENTS.inc"
.include "tn13def.inc"

;=================================================================================================
;     * Имена регистров *
;=================================================================================================
.def  par1			= r16	.def light	= r16	.def Dms	= r16	.def Pms	= r16
.def  par2			= r17	.def dark	= r17	.def Dsec	= r17	.def Psec	= r17
.def  par3			= r18	.def flip	= r18	.def Dpause	= r18

.def  TimerSig_ms	= r19	.def par4	= r19	
.def  TimerSig_sec	= r20	.def par5	= r20	
.def  PauseSig_ms	= r21	.def par6	= r21
.def  PauseSig_sec	= r22	.def par7	= r22	

.def  temp			= r23
.def  Down			= r24	
.def  tempPORT		= r25
.def  PreSecondLOW	= r26
.def  kState		= r27	
.def  num			= r28	
.def  mode			= r29
.def  Option		= r30	.def tempSREG = r30

.def  Boolean		= r31
;=================================================================================================
;     * Константы *
;=================================================================================================
.equ  inPreSecond		= 64;64		;приходится разбить на 2 байта отсчет для секунды т.к. 64*70 > 255. Поскольку мы оперируем с секундами и минутами, а не [мс], то можно схитрить и так.
.equ  inSecond			= 69;70		;примерно столько нужно раз сработать PreSecondHIGH, чтобы получилась секунда
.equ  inMinute			= 60;60		;[sec] через сколько секунд наступит минута(по умолчанию 60)

.equ  Iteration			= 0
.equ  CanReset			= 1
.equ  StartProgramm		= 2
.equ  Signal			= 3
.equ  var4				= 4
.equ  var5				= 5
.equ  var6				= 6
.equ  var7				= 7

.equ  delayPress		= 25			;задержка для дребезга (в пресекундах или итерациях осн. цикла)
.equ  delayNormMode		= inSecond*0.75	;[ms]  задержка нажатия во время набора
.equ  delayHardMode		= 2				;[sec] задержка нажатия для перехода в другие режимы
.equ  delayMinReset		= 2				;[ms]  минимальное  время нажатия для сброса
.equ  delayMaxReset		= inSecond*0.5	;[ms]  максимальное время нажатия для сброса
.equ  delayBeforeStart	= inSecond*0.5	;[ms]  задержка перед стартом после отпускания кнопки набора

.equ  TIMER_1  = 15		;15
.equ  TIMER_2  = 15		;15
.equ  TIMER_3  = 15		;15
.equ  TIMER_4  = 15		;15
.equ  TIMER_11 = 5		;5
.equ  TIMER_12 = 10		;10
.equ  TIMER_88 = 999	;infinity

.equ  COUNT_END	= 7		;7
.equ  COUNT_1	= 1		;1
.equ  COUNT_2	= 2		;2
.equ  COUNT_3	= 3		;3
.equ  COUNT_4	= 4		;4
.equ  COUNT_11	= 1		;1
.equ  COUNT_12	= 2		;2
.equ  COUNT_88	= 4		;4

;A - сигнал для основных режимов
.equ  timerAsec = 0						;[sec] время сигнала
.equ  timerAms  = inSecond*0.8			;[ms]  время сигнала
.equ  widthAsec = 0						;[sec] продолжительность сигнала
.equ  widthAms  = inSecond*0.4			;[ms]  продолжительность сигнала

;B - сигнал для дополнительных режимов
.equ  timerBsec = 0						;[sec] время сигнала
.equ  timerBms  = inSecond*0.36			;[ms]  время сигнала
.equ  widthBsec = 0						;[sec] продолжительность сигнала
.equ  widthBms  = inSecond*0.18			;[ms]  продолжительность сигнала


.dseg
#define	DefineTimer(X)	mmDelay##X##_ms:.byte 1  mmDelay##X##_sec:.byte 1  Pause##X:.byte 1
		DefineTimer(A)
		DefineTimer(B)
		DefineTimer(C)
		
		mmPreMode:			.byte 1
			
		mmPress_ms:			.byte 1
		mmPress_sec:		.byte 1
		mmCountSignal:		.byte 1	
		mmTimeWork:			.byte 1	

		mmDARK:				.byte 1
		mmFLIP:				.byte 1
		mmEND:				.byte 1
		mmDELAY_sec:		.byte 1
		mmDELAY_ms:			.byte 1
;=================================================================================================
;     * Макросы *
;=================================================================================================
;-------------------------------------------------------------------------------------------------
.macro outi
	ldi temp, @1
	out @0, temp
.endm
.macro flag
	set_bit @0,@1,Boolean
.endm
.macro invert
	ldi temp, (1<<@0)
	eor Boolean, temp
.endm
.macro IFb
	get_bit temp,@0,Boolean
	IF  temp,@1,(@2<<@0)
.endm
.macro IFFb
	get_bit temp,@0,Boolean
	IFF temp,@1,(@2<<@0)
.endm
;-------------------------------------------------------------------------------------------------
.macro writeRAMr
	sts @0,@1
.endm
.macro writeRAM
	ldi temp,@1
	sts @0,temp
.endm
.macro readRAM
	lds @0,@1
.endm
.macro decRAM
	lds temp,@0
	dec temp
	sts @0,temp
.endm
.macro incRAM
	lds temp,@0
	inc temp
	sts @0,temp
.endm
.macro IFram
	readRAM temp,@0
	IF      temp,@1,@2
.endm
.macro IFramr
	readRAM temp,@0
	IFr     temp,@1,@2
.endm
.macro IFFram
	readRAM temp,@0
	IFF     temp,@1,@2
.endm
;-------------------------------------------------------------------------------------------------
.macro FFFcall
	lds par1,@1
	lds par2,@2
	lds par3,@3
	rcall @0	
	sts  @3,par3
	sts  @2,par2
	sts  @1,par1
.endm
.macro SetTimer
	.if   @1>0  && @2==0
		writeRAM mmDelay@0_sec,@1
	.elif @1==0 && @2>0
		writeRAM mmDelay@0_ms, @2
	.elif @1>0  && @2>0
		writeRAM mmDelay@0_sec,@1
		writeRAM mmDelay@0_ms, @2
	.endif	
.endm
.macro UpdateTimer
	FFFcall _UpdateTimer_,mmDelay@0_ms,mmDelay@0_sec,Pause@0
.endm
;-------------------------------------------------------------------------------------------------
.macro TimeSignal
	.set TimeA = @0*inSecond + @1		//переводим заданное время в типа ~[ms] (1/70 [c])
	.set TimeB = @2*inSecond + @3
	.set TimeB = TimeA - TimeB
	.set Asec  = TimeA/inSecond
	.set Bsec  = TimeB/inSecond
	.set Ams   = TimeA%inSecond
	.set Bms   = TimeB%inSecond
	.if(Asec > 0)
		ldi  TimerSig_sec, Asec
	.endif
	.if(Ams  > 0)
		ldi  TimerSig_ms,  Ams
	.endif
	.if(Bsec > 0)
		ldi  PauseSig_sec, Bsec
	.endif
	.if(Bms  > 0)
		ldi  PauseSig_ms,  Bms
	.endif
.endm
.macro SetSignal
	TimeSignal @0,@1,@2,@3
	rcall _UpdateSignal_
.endm
;-------------------------------------------------------------------------------------------------
;=================================================================================================
;     * Инициализация *
;=================================================================================================
.cseg
.org 0x0000	
		rjmp    Reset
.org 0x0005								;прерывание по изменению переполнению
		rjmp	Interrupt				;переход к программе обработки прерывания

Reset:
		cli
		
		ldi   num,0b00000001
		ldi   mode,0
		ldi   Option,0
		ldi   kState,0
		ldi   Boolean,0
		ldi   PreSecondLOW,0
		ldi   TimerSig_ms, 0
		ldi   TimerSig_sec,0
		ldi   PauseSig_ms, 0
		ldi   PauseSig_sec,0

		rcall UpdateMode		;вызываем для очистки некоторых переменный в ОЗУ

		ldi   temp,0
		sts   mmDelayA_ms, temp
		sts   mmDelayA_sec,temp
		sts   mmDelayB_ms, temp
		sts   mmDelayB_sec,temp
		sts   mmDelayC_ms, temp
		sts   mmDelayC_sec,temp

		outi TCCR0B, 0b00000001
		outi TIMSK0, 0b00000010

		outi  SPL  , RAMEND		 ;инициализация стека
		outi  DDRB , 0b11010111	 ;Назначаеем PВ3 входом, остальные выходами
		outi  PORTB, 0b00001000	 ;Включаем подтяжку на PВ3

		sei
;=================================================================================================
;     * Главный цикл *
;=================================================================================================
main:
	sbis PINB,3			rjmp main

MainLoop:									;работа программы гарантируется если основной цикл будет 
											;выполнятся быстрее чем произойдет прерывание
	IFFb Iteration,'=',0
						rjmp MainLoop

	in	 tempPORT, PINB
	andi tempPORT, 0b11101000				;гасим 0й, 2й, 4й, и выключаем звук


	;--------   KeyState   --------
	sbic  PINB,3		dec kState
	sbis  PINB,3		inc kState

	IF  kState, '<',-delayPress
		ldi  kState,-delayPress
		ldi  Down,0
	endIF
	IF  kState, '>', delayPress
		ldi  kState, delayPress
		ldi  Down,1
	endIF
	;------------------------------
	;--------  PressState  --------
	lds Psec, mmPress_sec				;главное чтобы во время использования этих переменных
	lds Pms,  mmPress_ms				;они не перезаписались какойнибудь функцией с par1, par2, ...
	IF  PreSecondLOW,'=',0				;каждую 1/70 секунды проверяем состояние
		IFF Down,'=',0
				rcall ClearPress	
		
		IF  Down,'=',1
			inc Pms
			IF  Pms,'=',inSecond
				ldi Pms,0				
				inc Psec	sts mmPress_sec,Psec
			endIF
			sts mmPress_ms,Pms
		endIF
	endIF
	;------------------------------
	;----------------------------------------------------
	IF  Option,'=',0
		IF  mode,'<',4
		IF  Down,'=',1
		IF  Pms,'=',delayNormMode
			inc   mode
			rcall ClearPress
		endIF
		endIF
		endIF
		IF  mode,'>',0
		IF  Down,'=',0
			SetTimer B, 0,delayBeforeStart
			SetSignal   timerAsec,timerAms,  widthAsec,widthAms
			rcall ClearPress  ldi Option,1		flag CanReset,1
		endIF
		endIF
	endIF
	;----------------------------------------------------
	IF  Option,'=',1
		IFram PauseB,'=',0
			ldi    Option,2	
			flag   StartProgramm,1
			SetTimer C, inMinute,0
		endIF
	endIF
	;----------------------------------------------------
	IF  Option,'=',2
		IF  Down,'=',1
		IF	Psec,'=',delayHardMode
			IFF mode,'=',1
							ldi mode,11
			IFF mode,'=',2
							ldi mode,12
			IFF mode,'=',4
							ldi mode,88
		endIF
		endIF
	endIF
	;----------------------------------------------------
	IFb CanReset,'=',1
	IF  Down,'=',0
		IF Psec,'=',0
		IF Pms, '>',delayMinReset
		IF Pms, '<',delayMaxReset
								rjmp Reset
		endIF
		endIF
		endIF
	endIF
	endIF
	;----------------------------------------------------
	IFramr mmPreMode,'!',mode
			rcall  UpdateMode
	endIF
	;------------------------------------------------------
	lds dark, mmDARK
	lds flip, mmFLIP
	IFb StartProgramm,'=',1
		IFram  PauseB,'=',0
			lds	temp,mmDELAY_sec	sts	mmDelayB_sec,temp
			lds temp,mmDELAY_ms		sts mmDelayB_ms, temp

			eor dark,flip				

			lds par1,mmEnd
			IF  par1,'!',0
				rcall Flipping

				mov temp,par1
				and temp,flip

				IF  temp,'>',0
					IF  par1,'>',0
						eor flip,par1
					endIF
 					IF  par1,'<',0
						ldi temp,0b10000000	eor dark,temp	rcall Flipping
					endIF
				endIF
			endIF
		endIF
		IFram PauseC,'=',0
			  lds temp,mmTimeWork
			  IF  temp,'>',0
			  dec temp
			  sts mmTimeWork,temp
			  IF  temp,'=',0
				  dec  mode
				  IFF  mode,'{',0
								ldi mode,-1
				  IFF  mode,'}',10
								ldi mode,-1
			  endIF
			  endIF
			  SetTimer C, inMinute,0
		endIF
		
		ori  tempPORT,0b00100000
	endIF
	sts mmDARK, dark
	sts mmFLIP, flip
	;------------------------------------------------------
	mov light,num
	and light,dark
	;------------------------------------------------------
	IFF light,'=',0b00000010
									ori tempPORT,0b00000101
	IFF light,'=',0b00000100
									ori tempPORT,0b00010000
	IFF light,'=',0b00001000
									ori tempPORT,0b00000001
	IFF light,'=',0b00010000
									ori tempPORT,0b00010100
	;------------------------------------------------------
	UpdateTimer C
	UpdateTimer B
	UpdateTimer A
	IF	Dpause,'=',0
		lds  temp,mmCountSignal
		dec  temp
		sts  mmCountSignal,temp
		IF   temp,'>',0
				rcall _UpdateSignal_
		endIF
		IF   temp,'=',0
		IFF  mode,'=',-1
				rjmp Reset
		endIF
	endIF
	IF	Dsec,'}',0
	IF	Dms, '>',0
		IFr  Dsec,'=',PauseSig_sec
		IFr  Dms, '=',PauseSig_ms
				flag Signal,0
		endIF
		endIF

		IFFb Signal,'=',1
				ori tempPORT,0b00000010
	endIF
	endIF
	;---------------------------------------------------
									;при отпускании кнопки на ножке образуется неопределенное состояние
	ori tempPORT, 0b00001000		;поэтому подтягиваем ножку контролера к 5V - "кнопка не нажата"
	out    PORTB, tempPORT

	flag  Iteration,0
rjmp MainLoop
;=================================================================================================
;     * Функции *
;=================================================================================================
ClearPress:
	ldi Psec,0	sts mmPress_sec,Psec
	ldi Pms, 0	sts mmPress_ms, Pms	
ret
;-------------------------------------------------------------------------------------------------
_UpdateSignal_:
	sts  mmDelayA_sec, TimerSig_sec
	sts  mmDelayA_ms,  TimerSig_ms
	flag Signal,1
ret
;-------------------------------------------------------------------------------------------------
_UpdateTimer_:
	ldi Dpause,1

	IF  PreSecondLOW,'=',0			;обновляем задержку каждую 1/70 секунды
		dec Dms
		IF  Dms, '=',0
		IF  Dsec,'=',0
			ldi Dpause,0			;после заводки таймера сработает 1 раз (с 1 мс на 0 мс)
		endIF
		endIF
		IF  Dms,'{',0
			ldi Dms,inSecond
			dec Dsec
			IF  Dsec,'<',0			
				ldi Dms,0	ldi Dsec,0
			endIF
		endIF
	endIF
ret
;-------------------------------------------------------------------------------------------------
UpdateMode:		
	sts mmPreMode,mode

	IF  mode,'=',-1
		TimeSignal timerAsec,timerAms,  widthAsec,widthAms
		flag StartProgramm,0
		ldi  temp, COUNT_END
	endIF
	IF mode,'>', 10
		TimeSignal timerBsec,timerBms,  widthBsec,widthBms
	endIF

	push par4	
	push par5
	push par6

	ldi par1,0	  ;end
	ldi dark,0	  ;par2
	ldi flip,0	  ;par3
	ldi par4,0	  ;Blink		[ms]
	ldi par5,0	  ;Blink		[sec]
	ldi par6,0	  ;TimeWork		[min]
		
	IF mode,'=', 1
		ldi dark, 0b00000010
		ldi flip, 0b00000010
		ldi par4, inSecond
		ldi par6, TIMER_1
		ldi temp, COUNT_1
	endIF
	IF mode,'=', 2
		ldi dark, 0b00000110
		ldi flip, 0b00000100
		ldi par4, inSecond
		ldi par6, TIMER_2
		ldi temp, COUNT_2
	endIF
	IF mode,'=', 3
		ldi dark, 0b00001110
		ldi flip, 0b00001000
		ldi par4, inSecond
		ldi par6, TIMER_3
		ldi temp, COUNT_3
	endIF
	IF mode,'=', 4
		ldi dark, 0b00011110
		ldi flip, 0b00010000
		ldi par4, inSecond
		ldi par6, TIMER_4
		ldi temp, COUNT_4
	endIF
	IF mode,'=', 11
		ldi dark, 0b00000010
		ldi flip, 0b00000110
		ldi par1, 0b10001001
		ldi par4, inSecond/2
		ldi par6, TIMER_11
		ldi temp, COUNT_11
	endIF
	IF mode,'=', 12
		ldi dark, 0b00000010
		ldi flip, 0b00000110
		ldi par1, 0b10010001
		ldi par4, inSecond/4
		ldi par6, TIMER_12
		ldi temp, COUNT_12
	endIF
	IF mode,'=', 88
		ldi dark, 0b00010010
		ldi flip, 0b00010010
		ldi par4, inSecond
		ldi temp, COUNT_88
	endIF

	sts mmEND,		   par1
	sts mmDARK,        dark
	sts mmFLIP,        flip
	sts mmDELAY_ms,    par4
	sts mmDELAY_sec,   par5
	sts mmTimeWork,    par6
	sts mmCountSignal, temp


	pop par6
	pop par5
	pop par4

	rcall _UpdateSignal_
ret
;-------------------------------------------------------------------------------------------------
Flipping:
	IFF dark,'>',0
				lsl flip
	IFF dark,'<',0
				lsr flip
ret
;-------------------------------------------------------------------------------------------------
Interrupt:
	push temp
	push tempSREG
	in   tempSREG,SREG
	;------------------
	outi TCNT0, 0	

	lsl num						;счетчик от 1 до 4 по которому загораются соответствующие светодиоды
	IFF num,'=',0b00100000
		ldi num,0b00000010

	inc  PreSecondLOW
	IFF  PreSecondLOW,'=',inPreSecond
			ldi PreSecondLOW,0	

	flag Iteration,1			;синхронизируем основной цикл с прерываниями
	;------------------
	out  SREG,tempSREG
	pop  tempSREG
	pop  temp
reti

