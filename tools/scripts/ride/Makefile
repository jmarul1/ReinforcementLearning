## CHANGE THE FOLLOWING AS NECESSARY ###########################################
UPF     := ~/tcad/upffiles/p1269_4x0r0v5.upf
MODEL   := y89indpci2
SCRIPT  := ~/tcad/ride/scripts
## END OF MODIFIABLE VARIABLES #################################################

WORKDIR := work

all:	work/fitting

work/fitting:	work/runs
		@mkdir -p work/fitting;
		@cp -f work/runs/*.s[23]p work/fitting;
		@$(SCRIPT)/sparam2Presto work/fitting $(MODEL)

work/runs:
	@$(SCRIPT)/rideGenerateSkews -upf $(UPF) -inds `pwd`/inds -execute $(WORKDIR)

check:	all
	@mkdir -p spxtract;
	@cd spxtract && ln -sf ../$(MODEL).sp .;
	@cd spxtract && for temp in -10 -5 0 25 50 75 85 95 110 125; do $(SCRIPT)/spXtract $(MODEL).sp -i -mp -temp $$temp -extension t$$temp; done

clean:
	rm -rf $(WORKDIR)

refit:
	rm -rf $(WORKDIR)/fitting;

.PHONY:	all clean check
