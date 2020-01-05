Cristian Ferrari 810932

PROGETTO "DA REGEX A NFA".


------- PARTE PROLOG -----------------


Il progetto consiste in 3 predicati principali

- is_regexp/1

	Predicato che risulta vero quando l'input 'RE' è riconosciuto come una regex
	Il predicato controlla se l'input appartiene alla categoria di atom/1 o compound/1, nel
	caso in cui appartengano a compound viene controllata la presenza di operatori riservati
	(seq, or, star, plus) che vengono processati diversamente, per gli operatori unari
	viene controllato il numero di argomenti passati, il predicato fallisce se star/plus 
	contengono più di un argomento, mentre nel caso di seq/or viene gestito il caso degenere
	normalmente senza che il predicato fallisca
	Gli operatori non riservati sono considerati come semplici simboli e quindi accettati da
	is_regexp
	Una Lista è considerata un simbolo unico
	Esempio:
	
		is_regexp(seq([a,b])).

		[a,b] = simbolo

	 	il predicato sarà quindi vero

- nfa_regexp_comp/2

	Predicato responsabile per la generazione dell'automa che sarà contrassegnato con FA_Id
	secondo la regex 'RE', il predicato controlla che l'FA_Id inserito sia valido e che non sia
	già in utilizzo ritornando errore altrimenti
	Il predicato controlla per prima cosa che 'RE' sia una regex.
	Viene utilizzato il predicato 'gensym' per la generazione di nuovi stati che vengono inseriti
	nella base di dati tramite 'assert' nel formato:

		nfa_initial(FA_Id, <Stato iniziale>).
		nfa_final(FA_Id, <Stato Finale>).

	per stato iniziale e finale

		nfa_delta(FA_Id, <stato 1>, <simbolo>, <stato 2>) 

	Il predicato gestisce i casi dei vari operatori generando l'NFA secondo l'algoritmo di 
	Thompson, il predicato gestisce i casi degeneri di Seq/Or permettendo l'utilizzo di seq/1 e
	or/1
	Come per is_regexp/1 gli operatori non riservati sono accettati come simboli
	L'utilizzo dell'operatore =.. per controllare la presenza di operatori riservati 
	rende necessario gestire il caso in cui 'RE' sia una lista

	or_handler: predicate ausiliario per la generazione dell'automa in caso di predicato or
		    secondo l'algoritmo di Thompson

- nfa_test/2

	Predicato che controlla qualora l'input dato sia accettato dall'NFA contrassegnato con
	FA_Id, per prima cosa viene controllato che FA_Id esista e che l'input sia una lista, da 
	errore in caso contrario, chiama poi il predicato nfa_test_in
	
	nfa_test_in : predicato responsabile per l'effettivo controllo dell'input, controlla per
		      diversi casi base come input vuoto chiamando poi nfa_test_in/3 passando anche
		      lo stato corrente, quest'ultimo controlla per casi base come input vuoto,
		      epsilon transition e epsilon transition con input vuoto oppure controlla
		      semplicemente l'esistenza di un fatto del tipo:

				nfa_delta(FA_Id, Stato_corrente, <simbolo>, Stato_finale)

		      per poi richiamarsi ricorsivamente consumando il simbolo corrente di input

PREDICATI DI UTILITY

- nfa_clear/1 e nfa_clear/0

	Utilizza semplicemente il predicato retractall/1 per eliminare tutti gli stati (o solo quelli
	associati con FA_Id nel caso di nfa_clear/1) dalla base di conoscenza

- nfa_list/1 e nfa_list/0
	
	Utilizza il predicato listing/1 per mostrare a video tutti gli stati (o solo quelli associati
	a FA_Id nel caso di nfa_list/1)

- Predicati Check

	Insieme di predicati utilizzati per gestire i casi di errori utilizzando il predicato 
	throw/1 e catch/3 con nfa_error/1 per stampare vari message di errore
	
	
	



















