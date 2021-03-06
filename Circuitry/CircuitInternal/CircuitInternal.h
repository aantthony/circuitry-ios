//
//  CircuitInternal.h
//  Circuitry
//
//  Created by Anthony Foster on 20/12/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#ifndef __Circuitry__CircuitInternal__
#define __Circuitry__CircuitInternal__
#include "MongoIDType.h"

struct CircuitInternal;

struct CircuitObject;
struct CircuitLink;
struct CircuitProcess;

typedef struct CircuitInternal CircuitInternal;

typedef struct CircuitObject CircuitObject;
typedef struct CircuitLink CircuitLink;
typedef struct CircuitProcess CircuitProcess;

extern int CircuitObjectFlagLocked;

// Lifecycle:
CircuitInternal * CircuitCreate();
void CircuitDestroy(CircuitInternal *c);


// Operations:
CircuitObject *CircuitObjectFindById(CircuitInternal *c, ObjectID id);

// (Simulation)
int CircuitSimulate (CircuitInternal *c, int ticks);

// (Edit Objects)
CircuitObject * CircuitObjectCreate(CircuitInternal *c, CircuitProcess *type);
void CircuitObjectRemove(CircuitInternal *c, CircuitObject *o);

// (Edit Links)
CircuitLink *CircuitLinkCreate(CircuitInternal *c, CircuitObject *object, int index, CircuitObject *target, int targetIndex);
void CircuitLinkRemove(CircuitInternal *c, CircuitLink *link);

// (Edit state)
void CircuitObjectSetInput(CircuitInternal *c, CircuitObject *o, int input);
void CircuitObjectSetOutput(CircuitInternal *c, CircuitObject *o, int output);
void CircuitObjectSetInputBit(CircuitInternal *c, CircuitObject *o, int inputIndex, int inputBit);
void CircuitObjectSetOutputBit(CircuitInternal *c, CircuitObject *o, int outputIndex, int outputBit);


// (Read state)

// Base functionality:

extern CircuitProcess CircuitProcessIn;
extern CircuitProcess CircuitProcessOut;
extern CircuitProcess CircuitProcessButton;
extern CircuitProcess CircuitProcessPushButton;
extern CircuitProcess CircuitProcessLight;
extern CircuitProcess CircuitProcessLightGreen;
extern CircuitProcess CircuitProcessOr;
extern CircuitProcess CircuitProcessNot; 
extern CircuitProcess CircuitProcessNor;  
extern CircuitProcess CircuitProcessXor;   
extern CircuitProcess CircuitProcessXnor;    
extern CircuitProcess CircuitProcessAnd;   
extern CircuitProcess CircuitProcessNand; 
extern CircuitProcess CircuitProcessHA;
extern CircuitProcess CircuitProcessFA;
extern CircuitProcess CircuitProcessBinDec;
extern CircuitProcess CircuitProcessAdd8;
extern CircuitProcess CircuitProcessMult8;
extern CircuitProcess CircuitProcessAdd4;
extern CircuitProcess CircuitProcessMult4;
extern CircuitProcess CircuitProcessBin7Seg;
extern CircuitProcess CircuitProcess7Seg;
extern CircuitProcess CircuitProcess7SegBin;
extern CircuitProcess CircuitProcessClock;
extern CircuitProcess CircuitProcessJK;
extern CircuitProcess CircuitProcessSER;
extern CircuitProcess CircuitProcessSR;
extern CircuitProcess CircuitProcessT;
extern CircuitProcess CircuitProcessD;
extern CircuitProcess CircuitProcessD4;
extern CircuitProcess CircuitProcessD8;
extern CircuitProcess CircuitProcessD16;


// Structure:

// (Immutable)
struct CircuitInternal {
    
    // Double buffer:
    CircuitObject **needsUpdate;
    CircuitObject **needsUpdate2;
    int needsUpdate_count;
    int needsUpdate_size;
    
    // All links:
    CircuitLink *links;
    int links_count;
    int links_size;
    
    // Pointers to clocks (clocks are stored as objects)
    CircuitObject **clocks;
    int clocks_count;
    int clocks_size;
    
    // All objects:
    CircuitObject *objects;
    int objects_count;
    int objects_size;
    
};

// (Immutable)
struct CircuitProcess {
    const char *id;
    int numInputs;
    int numOutputs;
    int (*calculate)(int, unsigned int*);
};


// (Immutable)
struct CircuitLink {
    CircuitLink *nextSibling;
    int sourceIndex;
    int targetIndex;
    CircuitObject *source;
    CircuitObject *target;
};

// (Immutable)
struct CircuitObject {
    ObjectID id;
    int in;
    int out;
    CircuitProcess *type;
    unsigned int flags;
    unsigned int data;
    
    union { struct {float x, y, z;}; struct {float v[3];}; } pos;
    
    char name[4];
    CircuitLink **outputs;
    CircuitLink **inputs;
};


#endif