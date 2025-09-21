# #https://www.physionet.org/physiotools/wag/annot-5.htm

# #ifndef wfdb_ECGCODES_H	/* avoid multiple definitions */
# #define wfdb_ECGCODES_H
# NOTQRS=0 #	/* not-QRS (not a getann/putann code) */
# NORMAL=1 #	/* normal beat */
# LBBB=2 #	/* left bundle branch block beat */
# RBBB=3 #	/* right bundle branch block beat */
# ABERR=4 #	/* aberrated atrial premature beat */
# PVC=5 #	/* premature ventricular contraction */
# FUSION=6 #	/* fusion of ventricular and normal beat */
# NPC=7 #	/* nodal (junctional) premature beat */
# APC=8 #	/* atrial premature contraction */
# SVPB=9 #	/* premature or ectopic supraventricular beat */
# VESC=10 #	/* ventricular escape beat */
# NESC=11 #	/* nodal (junctional) escape beat */
# PACE=12 #	/* paced beat */
# UNKNOWN=13 #	/* unclassifiable beat */
# NOISE=14 #	/* signal quality change */
# ARFCT=16 #	/* isolated QRS-like artifact */
# STCH=18 #	/* ST change */
# TCH=19 #	/* T-wave change */
# SYSTOLE=20 #	/* systole */
# DIASTOLE=21 #	/* diastole */
# NOTE=22 #	/* comment annotation */
# MEASURE=23 #	/* measurement annotation */
# PWAVE=24 #	/* P-wave peak */
# BBB=25 #	/* left or right bundle branch block */
# PACESP=26 #	/* non-conducted pacer spike */
# TWAVE=27 #	/* T-wave peak */
# RHYTHM=28 #	/* rhythm change */
# UWAVE=29 #	/* U-wave peak */
# LEARN=30 #	/* learning */
# FLWAV=31 #	/* ventricular flutter wave */
# VFON=32 #	/* start of ventricular flutter/fibrillation */
# VFOFF=33 #	/* end of ventricular flutter/fibrillation */
# AESC=34 #	/* atrial escape beat */
# SVESC=35 #	/* supraventricular escape beat */
# LINK=36 #	/* link to external data (aux contains URL) */
# NAPC=37 #	/* non-conducted P-wave (blocked APB) */
# PFUS=38 #	/* fusion of paced and normal beat */
# WFON=39 #	/* waveform onset */
# PQ= WFON	/* PQ junction (beginning of QRS) */
# WFOFF=40 #	/* waveform end */
# JPT=WFOFF	#/* J point (end of QRS) */
# RONT=41 #	/* R-on-T premature ventricular contraction */

# # /* ... annotation codes between RONT+1 and ACMAX inclusive are user-defined */

# ACMAX=49 #	/* value of largest valid annot code (must be < 50) */

# #endif
