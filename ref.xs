#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int init_done = 0;

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

void evil_ref_redirect () {
    /* TODO: This finds all existing code and replaces ppaddr with the
       new pointer. */
}

MODULE = UNIVERSAL::ref	PACKAGE = UNIVERSAL::ref

BOOT:
if ( ! init_done++  ) {
    /* Is this a race in threaded perl? */
    real_pp_ref = PL_ppaddr[OP_REF];
    PL_ppaddr[OP_REF] = Perl_pp_evil_ref;
    evil_ref_redirect();
}
