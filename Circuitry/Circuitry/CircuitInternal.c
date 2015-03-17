//
//  CircuitInternal.c
//  Circuitry
//
//  Created by Anthony Foster on 20/12/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#include "CircuitInternal.h"
#include <stdlib.h>
#include <unistd.h>


void fail(const char * message) {
//    fprintf(stderr, "Internal Consistency Exception: %s", message);
    exit(500);
}

static void *smalloc(size_t c) {
    return malloc(c);
}
static void *scalloc(size_t c, size_t b) {
    return calloc(c, b);
}

// Logic Gate definitions:

static int XOR  (int x, void *d) { return x == 1 || x == 2;}
static int XNOR (int x, void *d) { return x == 0 || x == 3;}
static int AND  (int x, void *d) { return x == 3;}
static int NAND (int x, void *d) { return x != 3;}
static int NOT  (int x, void *d) { return !x; }
static int NOR  (int x, void *d) { return !x; }
static int OR   (int x, void *d) { return !!x; }
static int HA   (int x, void *d) { int a = x & 1; int b = x >> 1; return a+b; }
static int FA   (int x, void *d) { int a = x & 1; int b = (x >> 1) & 1; int c = x >> 2; return a+b+c; }
static int ADD8 (int x, void *d) { return (x&255) + (x >> 8); }
static int MULT8 (int x, void *d) { return (x&255) * (x >> 8); }
static int ADD4 (int x, void *d) { return (x&15) + (x >> 4); }
static int MULT4 (int x, void *d) { return (x&15) * (x >> 4); }
static int BINDEC (int x, void *d) { return 1 << x; }
static int BIN7SEG(int x, void *d) {
    switch(x) {
        case 0:  return 0b0111111;
        case 1:  return 0b0000110;
        case 2:  return 0b1011011;
        case 3:  return 0b1001111;
        case 4:  return 0b1100110;
        case 5:  return 0b1101101;
        case 6:  return 0b1111101;
        case 7:  return 0b0000111;
        case 8:  return 0b1111111;
        case 9:  return 0b1101111;
        case 10: return 0b1110111;
        case 11: return 0b1111100;
        case 12: return 0b1011000;
        case 13: return 0b1011110;
        case 14: return 0b1111001;
        case 15: return 0b1110001;
        default: return 0;
    }
}

CircuitProcess CircuitProcessIn      = {"in",       0,  1, NULL };
CircuitProcess CircuitProcessOut     = {"out",      1,  0, NULL };
CircuitProcess CircuitProcessButton  = {"button",   0,  1, NULL };
CircuitProcess CircuitProcessPushButton = {"pbtn",  0,  1, NULL };
CircuitProcess CircuitProcessLight   = {"light",    1,  0, NULL };
CircuitProcess CircuitProcessLightGreen = {"lightg",1,  0, NULL };
CircuitProcess CircuitProcessOr      = {"or",       2,  1, OR };
CircuitProcess CircuitProcessNot     = {"not",      1,  1, NOT };
CircuitProcess CircuitProcessNor     = {"nor",      2,  1, NOR };
CircuitProcess CircuitProcessXor     = {"xor",      2,  1, XOR };
CircuitProcess CircuitProcessXnor    = {"xnor",     2,  1, XNOR };
CircuitProcess CircuitProcessAnd     = {"and",      2,  1, AND };
CircuitProcess CircuitProcessNand    = {"nand",     2,  1, NAND };
CircuitProcess CircuitProcessHA      = {"ha",       2,  2, HA };
CircuitProcess CircuitProcessFA      = {"fa",       3,  2, FA };
CircuitProcess CircuitProcessBinDec  = {"bindec",   4, 16, BINDEC };
CircuitProcess CircuitProcessAdd8    = {"add8",    16,  9, ADD8 };
CircuitProcess CircuitProcessMult8   = {"mult8",   16,  8, MULT8 };
CircuitProcess CircuitProcessAdd4    = {"add4",     8,  5, ADD4 };
CircuitProcess CircuitProcessMult4   = {"mult4",    8,  4, MULT4 };
CircuitProcess CircuitProcessBin7Seg = {"bin7seg",  4,  7, BIN7SEG };
CircuitProcess CircuitProcess7Seg    = {"7seg",     7,  0, NULL };
CircuitProcess CircuitProcessClock   = {"clock",    0,  1, NULL };

CircuitObject *CircuitObjectFindById(CircuitInternal *c, ObjectID id) {
    for(int i = c->objects_count - 1; i >= 0; i--) {
        CircuitObject *o = &c->objects[i];
        if (!o) continue;
        if (o->id.m[0] == id.m[0] && o->id.m[1] == id.m[1] && o->id.m[2] == id.m[2]) return o;
    }
    return NULL;
}


static void *reallocLinks(CircuitInternal *c) {
    c->links_size *= 2;
    void *oldPtr = c->links;
    void *newPtr = realloc(oldPtr, sizeof(CircuitLink) * c->links_size);
    c->links = newPtr;
    
    long int offsetBytes = newPtr - oldPtr;
    
    if (!newPtr || offsetBytes == 0) {
        // nothing moved:
        return newPtr;
    }
    for (int i = 0; i < c->objects_count; i++) {
        CircuitObject *o = &c->objects[i];
        if (!o->type) continue;
        for(int j = 0; j < o->type->numInputs; j++) {
            void *inputLink = o->inputs[j];
            // This inputLink will be updated by one of the other passes below.
            // We only need to update our reference *to* it.
            o->inputs[j] = inputLink + offsetBytes;
        }
        for(int j = 0; j < o->type->numOutputs; j++) {
            void *first = o->outputs[j];
            o->outputs[j] = first + offsetBytes;
            CircuitLink *link = o->outputs[j];
            while(link) {
                void *nextSibling = link->nextSibling;
                link->nextSibling = nextSibling + offsetBytes;
                link = link->nextSibling;
            }
        }
    }
    return newPtr;
}

static void *reallocObjects(CircuitInternal *c) {
    c->objects_size *= 2;
    void *oldPtr = &c->objects;
    void *newPtr = realloc(oldPtr, sizeof(CircuitObject) * c->objects_size);
    c->objects = newPtr;
    
    long offsetBytes = newPtr - oldPtr;
    
    if (!newPtr || offsetBytes == 0) {
        // Nothing moved, all okay.
        return newPtr;
    }
    
    // Move all of the references to objects:
    for(int i = 0; i < c->links_count; i++) {
        CircuitLink *link = &c->links[i];
        if (!link->source) continue;
        void *source = link->source;
        link->source = source + offsetBytes;
        void *target = link->source;
        link->target = target + offsetBytes;
    }
    return newPtr;
}

static void reallocBuffer(CircuitInternal * c) {
    c->needsUpdate_size *= 2;
    c->needsUpdate  = realloc(&c->needsUpdate,  sizeof(void *) * c->needsUpdate_size);
    c->needsUpdate2 = realloc(&c->needsUpdate2, sizeof(void *) * c->needsUpdate_size);
}


// Queue a gate for a re-calculation
static void needsUpdate(CircuitInternal *c, CircuitObject *object) {
    for(int i = 0; i < c->needsUpdate_count; i++) {
        if (c->needsUpdate[i] == object) return;
    }
    c->needsUpdate_count++;
    if (c->needsUpdate_count > c->needsUpdate_size) {
        reallocBuffer(c);
    }
    c->needsUpdate[c->needsUpdate_count - 1] = object;
}

// Create a new circuit object (and queue it for recalculation)
CircuitObject * CircuitObjectCreate(CircuitInternal *c, CircuitProcess *type) {
    
    c->objects_count++;
    
    if (c->objects_count > c->objects_size) {
        if (!reallocObjects(c)) return NULL;
    }
    
    CircuitObject * o = &c->objects[c->objects_count - 1];
    
    o->in = 0;
    o->out = 0;
    o->id.m[0] = 0;
    o->id.m[1] = 0;
    o->id.m[2] = 0;
    o->type = type;
    o->pos.x = o->pos.y = o->pos.z = 0.0;
    o->name[0] = '\0';
    o->outputs = scalloc(o->type->numOutputs + o->type->numInputs, sizeof(CircuitLink *));
    o->inputs = o->outputs + o->type->numOutputs;
    
    if (type == &CircuitProcessClock) {
        c->clocks[c->clocks_count++] = o;
    }
    
    needsUpdate(c, o);
    
    return o;
}

// Remove a circuit object (and the links into and out of it)
// Automatically queues the outlet links targets for recalculation
void CircuitObjectRemove(CircuitInternal *c, CircuitObject *o) {
    for(int i = 0; i < o->type->numOutputs; i++) {
        while(o->outputs[i]) {
            CircuitLinkRemove(c, o->outputs[i]);
        }
    }
    for(int i = 0; i < o->type->numInputs; i++) {
        if (o->inputs[i]) {
            CircuitLinkRemove(c, o->inputs[i]);
        }
    }
    
    free(o->outputs);
    o->outputs = NULL;
    o->type = NULL;
    // TODO: we need to know the index of _items for this:
    // TODO: move the last object in _items to the the position of this object, and then fix all points to that last one
}


static CircuitLink *makeLink(CircuitInternal *c) {
    
    // TODO: search for existing space
    
    c->links_count++;
    
    if (c->links_count > c->links_size) {
        reallocLinks(c);
    }
    
    CircuitLink *link = &c->links[c->links_count - 1];
    link->nextSibling = NULL;
    link->sourceIndex = -1;
    link->targetIndex = -1;
    return link;
}

// Remove a link from the circuit, and queue its target for recalculation
void CircuitLinkRemove(CircuitInternal *c, CircuitLink *link) {
    if (link->target->in & 1<<link->targetIndex) {
        needsUpdate(c, link->target);
    }
    // first sibling:
    CircuitLink *prevSibling = link->source->outputs[link->sourceIndex];
    if (prevSibling == link) {
        // if this link is the first sibling, set the first sibling to equal the next sibling (or null)
        prevSibling = NULL;
        link->source->outputs[link->sourceIndex] = link->nextSibling;
    } else {
        // There are siblings inserted before. Find this link:
        while(prevSibling) {
            if (prevSibling->nextSibling == link) {
                // Found: Now prevSibling->nextSibling should be set to the next sibling (or null)
                break;
            }
            // nope: keep searching:
            prevSibling = prevSibling->nextSibling;
        }
        if (!prevSibling) {
            fail("Could not re-order siblings when removing link");
        }
        prevSibling->nextSibling = link->nextSibling;
    }
    
    if (link->target) {
        link->target->inputs[link->targetIndex] = NULL;
    }
    
    
    int mask = 1 << link->targetIndex;
    int oldIn = link->target->in;
    if (oldIn & mask) {
        link->target->in = oldIn & ~mask;
        needsUpdate(c, link->target);
    }
    
    link->nextSibling = NULL;
    link->sourceIndex = 0;
    link->targetIndex = 0;
    link->source = NULL;
    link->target = NULL;
}

// Add a link to the circuit (and will queue the targets recalculation if necessary). *All* links have a target (this is required for the CircuitInteral object to always be a consistent state). The half-made links in the Viewport are fakes.
CircuitLink *CircuitLinkCreate(CircuitInternal *c, CircuitObject *object, int index, CircuitObject *target, int targetIndex) {
    CircuitLink *prev = object->outputs[index];
    CircuitLink *link;
    
#ifdef DEBUG
    // Mindlessly continue...
#else
    if (index >= object->type->numOutputs) {
        fail("FAIL: Invalid Link: Attempted to create link from outlet, but there are not enough outlets.");
    }
    if (targetIndex >= target->type->numInputs) {
        fail("FAIL: Invalid Link: Attempted to create link into inlet, but the object doesn't have that many inlets.");
    }
    if (target->inputs[targetIndex] != NULL) {
        fail("Internal Consistency Exceptino: Invalid Link: Attempted to create link to inlet, but there is already an attachment there.");
    }
#endif
    
    if (!prev) {
        link = object->outputs[index] = makeLink(c);
    } else {
        while (prev->nextSibling && (prev = prev->nextSibling)) {}
        link = prev->nextSibling = makeLink(c);
    }
    link->source = object;
    link->target = target;
    link->sourceIndex = index;
    link->targetIndex = targetIndex;
    link->target->inputs[targetIndex] = link;
    
    // set value
    
    int mask = 1 << link->targetIndex;
    int oldIn = link->target->in;
    int oldBit = !!(oldIn & mask);
    int curIn = !!(link->source->out & 1 <<link->sourceIndex);
    if (!oldBit && curIn) {
        // it was turned on
        link->target->in = oldIn | mask;
        needsUpdate(c, link->target);
    } else if (oldBit && !curIn) {
        // it was turned off
        link->target->in = oldIn & ~mask;
        needsUpdate(c, link->target);
    } // otherwise it didn't change at all (and so no recalculations are required)
    
    return link;
}

void CircuitObjectSetInput(CircuitInternal *c, CircuitObject *o, int input) {
    o->in = input;
    needsUpdate(c, o);
}


void CircuitObjectSetOutput(CircuitInternal *c, CircuitObject *o, int output) {
    o->out = output;
    needsUpdate(c, o);
}

void CircuitObjectSetInputBit(CircuitInternal *c, CircuitObject *o, int inputIndex, int inputBit) {
    int bitMask = 1 << inputIndex;
    if (inputBit) {
        o->in |= bitMask;
    } else {
        o->in &= ~bitMask;
    }
    needsUpdate(c, o);
}

void CircuitObjectSetOutputBit(CircuitInternal *c, CircuitObject *o, int outputIndex, int outputBit) {
    int bitMask = 1 << outputIndex;
    if (outputBit) {
        o->out |= bitMask;
    } else {
        o->out &= ~bitMask;
    }
    needsUpdate(c, o);
}

/*
 Logic circuit simulation
 
 - How it works
 
 Each Circuit object maintains a double buffer (which is swapped every "tick") which is a list of gates which have been queued for re-calculation (calculating inputs based on outputs)
 The simulation will first do the recalcution, nulling out the buffer for gates which have not changed.
 Then it goes through that buffer again, skipping the nulls, and copies the ouputs to the connected gates, and queues them back into the loop if their inputs have changed. So it's an event loop.
 This continues until the number of ticks reaches the `ticks` argument.
 
 Return value: number of gates changed
 */

int CircuitSimulate(CircuitInternal *c, int ticks) {
    int nAffected = 0;
    for(int i = 0; i < ticks; i++) {
        
        int updatingCount = c->needsUpdate_count;
        if (!updatingCount) return nAffected;
        nAffected += updatingCount;
        CircuitObject **updating = c->needsUpdate;
        
        for(int i = 0; i < updatingCount; i++) {
            CircuitObject *o = updating[i];
            int oldOut = o->out;
            if (o->type == NULL) {
                // was deleted
                updating[i] = NULL;
                continue;
            }
            if (o->type->calculate == NULL) {
                // this doesn't actually need to be updated
                //                updating[i] = NULL;
                continue;
            }
            int newOut = o->type->calculate(o->in, o->data);
            // printf("     %s: gate with input: 0x%x  =  0x%x\n", o->type->id, o->in, o->out);
            if (oldOut != newOut) {
                o->out = newOut;
            } else {
                updating[i] = NULL;
            }
        }
        
        // Swap active buffer to clear:
        c->needsUpdate = c->needsUpdate2;
        c->needsUpdate_count = 0;
        
        // copy outputs of the recently recalculated gates to the inputs of those connected
        for(int i = 0; i < updatingCount; i++) {
            CircuitObject *o = updating[i];
            if (!o) continue;
            // printf("Copying output from %s gate 0x%x\n", o->type->id, o->out);
            int newOut = o->out;
            
            int jm = o->type->numOutputs;
            for(int j = 0; j < jm; j++) {
                int p = 1 << j;
                //int a = p & newOut, b = p & oldOut;
                //if (a != b) linksNeedsUpdate(c, o->outputs[j]);
                
                int a = !!(p & newOut);
                // printf("Outlet %d, place %d\n", j, a);
                CircuitLink *link = o->outputs[j];
                while(link) {
                    // printf("Write %d to %s gate\n", a, link->target->type->id);
                    int oldIn = link->target->in;
                    int mask = 1 << link->targetIndex;
                    int oldBit = !!(oldIn & mask);
                    if (oldBit != a) {
                        link->target->in = oldIn & ~ mask;
                        if (a) link->target->in |= mask;
                        // printf("Now that %s gate has input 0x%x\n", link->target->type->id, link->target->in);
                        needsUpdate(c, link->target);
                    } else break;
                    link = link->nextSibling;
                }
            }
        }
        
        // Swap back buffer
        c->needsUpdate2 = updating;
    }
    return nAffected;
}





void CircuitDestroy(CircuitInternal *c) {
    free(c->needsUpdate);
    free(c->needsUpdate2);
    free(c->links);
    free(c->objects);
    free(c->clocks);
    free(c);
}

CircuitInternal * CircuitCreate() {
    CircuitInternal *t = smalloc(sizeof(CircuitInternal));
    t->needsUpdate_count = 0;
    t->needsUpdate_size = 100000;
    t->needsUpdate  = smalloc(sizeof(CircuitObject *) * t->needsUpdate_size);
    t->needsUpdate2 = smalloc(sizeof(CircuitObject *) * t->needsUpdate_size);
    
    t->objects_count = 0;
    t->objects_size = 100000;
    t->objects = smalloc((sizeof(CircuitObject) * t->objects_size));
    
    t->links_count = 0;
    t->links_size = 100000;
    t->links = smalloc((sizeof(CircuitLink) * t->links_size));
    
    t->clocks_count = 0;
    t->clocks_size = 512;
    t->clocks = smalloc(sizeof(CircuitObject *) * t->clocks_size);
    return t;
}