#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef OP	*B__OP;

int init_done = 0;

#if 0
#define EVIL_REF_DEBUG(x) x
#else
#define EVIL_REF_DEBUG(x)
#endif

OP* (*real_pp_ref)(pTHX);
PP(pp_evil_ref) { 
    dSP; dTARG;
    SV* thing;
    SV* result;
    int count;
    HV* hooked_hv;
    char* hooked_class;
    I32 hooked_class_len;
    HE* he;
    bool is_hooked = 0;

    if ( OP_REF != PL_op->op_type ) {
        /* WTF called us? Whatever it is, I don't want to screw with it. */
        return real_pp_ref(aTHX);
    }

    /* Delegate to the pre-existing function if it isn't an object. */
    if ( ! sv_isobject( TOPs ) ) {
        /* I only mess with objects. */
        return real_pp_ref(aTHX);
    }

    /* Test for this object being hooked. */
    hooked_hv = get_hv( "UNIVERSAL::ref::hooked", 1 );
    hv_iterinit( hooked_hv );
    while( he = hv_iternext(hooked_hv) ) {
        hooked_class = hv_iterkey( he, &hooked_class_len );
        if ( sv_derived_from( TOPs, hooked_class ) ) {
            is_hooked = 1;
            break;
        }
    }

    /* Delegate to non-hooked objects */
    if ( ! is_hooked ) {
        return real_pp_ref(aTHX);
    }


    /* Start our scope. */
    thing = POPs;
    ENTER;
    SAVETMPS;

    /* Pass that as an argument to the callback. */
    /* TODO: list context. */
    PUSHMARK(SP);
    XPUSHs(thing);
    PUTBACK;
    count = call_pv( "UNIVERSAL::ref::hook", G_SCALAR );
    if ( 1 != count )
        croak("UNIVERSAL::ref::hook returned %d elements, expected 1", count);

    /* Get our result and increase its refcount so it won't be reaped
       by closing this scope. */
    /* TODO: list context. */
    SPAGAIN;
    result = POPs;
    SvREFCNT_inc(result);

    /* Close our scope. */
    FREETMPS;
    LEAVE;
    
    /* Just return whatever the callback returned. */
    assert( 1 == SvREFCNT(result));
    XPUSHs(result);
    RETURN;
}

void evil_ref_fixupop( OP* o ) {
  /* I'm seeing completely fruity ->op_sibling pointers and I think
     perhaps I shouldn't be looking at some ops. I'm hoping that
     requiring that I have a valid sort of class will prevent me
     from wandering into places I shouldn't be. */
  if ( !( OA_CLASS_MASK & PL_opargs[o->op_type] ) ) {
    return;
  }
  
  /* printf("OP=%x\n",o); */
  if ( o->op_type == OP_REF || o->op_ppaddr == real_pp_ref ) {
    EVIL_REF_DEBUG(printf("XXX\n"));
    o->op_ppaddr = Perl_pp_evil_ref;
  }

  EVIL_REF_DEBUG(printf("op_type=%d\n",o->op_type));
  EVIL_REF_DEBUG(printf("opargs=%x\n",PL_opargs[o->op_type]));
  EVIL_REF_DEBUG(printf("class=%x\n",OA_CLASS_MASK & PL_opargs[o->op_type]));
  EVIL_REF_DEBUG(printf("class=%x\n",(OA_CLASS_MASK & PL_opargs[o->op_type])>>OCSHIFT));

  if ( cUNOPx(o)->op_first ) {
    EVIL_REF_DEBUG(printf("->first=%x\n",cUNOPx(o)->op_first));
    evil_ref_fixupop(cUNOPx(o)->op_first);
  }

  if ( o->op_sibling ) {
    EVIL_REF_DEBUG(printf("->sibling=%x\n",o->op_sibling));
    evil_ref_fixupop(o->op_sibling);
  }
}

void evil_ref_fixupworld () {
    I32 i = 0;

    /* TODO: This finds all existing code and replaces ppaddr with the
       new pointer. */

    /* Fixup stuff that exists. */
/*
    if ( PL_main_root ) {
        EVIL_REF_DEBUG(printf("FIXING PL_main_root\n"));
        evil_ref_fixupop( PL_main_root );
    }
    if ( PL_eval_root ) {
        EVIL_REF_DEBUG(printf("FIXING PL_eval_root\n"));
        evil_ref_fixupop(PL_eval_root);
    }
    if ( PL_main_cv && CvROOT(PL_main_cv) ) {
        EVIL_REF_DEBUG(printf("FIXING PL_main_cv\n"));
        evil_ref_fixupop(CvROOT(PL_main_cv));
    }
    if ( PL_compcv && CvROOT(PL_compcv) ) {
        EVIL_REF_DEBUG(printf("FIXING PL_compcv\n"));
        evil_ref_fixupop(CvROOT(PL_compcv));
    }
*/

    /* Is this too sneaky to live? Dunno. */
    for ( i = 2; i < PL_savestack_max; i += 2 ) {
        if ( PL_savestack[i].any_i32 == SAVEt_SPTR
             && (    &PL_compcv  == PL_savestack[i-1].any_ptr
                  || &PL_main_cv == PL_savestack[i-1].any_ptr )
             && PL_savestack[i-2].any_ptr ) {
            EVIL_REF_DEBUG(printf("PL_compcv=%x\n", PL_savestack[i-2].any_ptr));
            EVIL_REF_DEBUG(printf("  file=%s\n",CvFILE((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  root=%x\n",CvROOT((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  gv=%x\n",CvGV((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  xsubany=%x\n",CvXSUBANY((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  xsub=%x\n",CvXSUB((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  start=%x\n",CvSTART((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  stash=%x\n",CvSTASH((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  depth=%x\n",CvDEPTH((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  padlist=%x\n",CvPADLIST((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  outside=%x\n",CvOUTSIDE((CV*)(PL_savestack[i-2].any_ptr))));
            EVIL_REF_DEBUG(printf("  flags=%x\n",CvFLAGS((CV*)(PL_savestack[i-2].any_ptr))));
            /* evil_ref_fixupop(CvROOT((CV*)(PL_savestack[i-2].any_ptr))); */
        }
    }
}

MODULE = UNIVERSAL::ref	PACKAGE = UNIVERSAL::ref PREFIX = evil_ref_

PROTOTYPES: ENABLE

BOOT:
if ( ! init_done++  ) {
    /* Is this a race in threaded perl? */
    real_pp_ref = PL_ppaddr[OP_REF];
    PL_ppaddr[OP_REF] = Perl_pp_evil_ref;
    evil_ref_fixupworld();
}

void
evil_ref_fixupop( o )
    B::OP o

void
evil_ref_fixupworld()
