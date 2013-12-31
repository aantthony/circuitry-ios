#import <stdio.h>
struct CircuitObject;

typedef struct CircuitObject CircuitObject;

struct CircuitObject {
    CircuitObject* child;
    int id;
    
    int numInputs;
    int numOutputs;
    
    int inputState;
    int outputState;
    
    int connections[];
};

typedef struct CircuitConnection {
    int numAttachments;
    int attachmentIds[];
} CircuitConnection;

typedef struct CircuitProgram {
    int id;
} CircuitProgram;

typedef struct {
    CircuitObject* firstChild;
    CircuitProgram* programs;
    CircuitConnection **connections;
} Circuit;

int CircuitProgramCustom = 1;
int CircuitProgramANDGate = 2;
int CircuitProgramORGate = 3;
int CircuitProgramNOTGate = 3;
int CircuitProgramXORGate = 4;
int CircuitProgramNORGate = 5;
int CircuitProgramNANDGate = 6;

CircuitObject *eventLoop[10 * 1048576];
int eventLoopIndex = 0;

void notifyCircuitObjectWasUpdated(Circuit *circuit, CircuitObject *object) {
    eventLoop[eventLoopIndex++] = object;
}

CircuitObject * getObjectById(Circuit *circuit, int objectId) {
    return 0;
}

void notifyCircuitConnectionWasUpdated(Circuit *circuit, int connectionId) {
    CircuitConnection *connection = circuit->connections[connectionId];
    int *attachmentIds = connection->attachmentIds;
    for(int i = 0; i < connection->numAttachments; i++) {
        int id = attachmentIds[i];
        if (!id) return;
        notifyCircuitObjectWasUpdated(circuit, getObjectById(circuit, id));
    }
}

int calculate(CircuitObject *object) {
    return 0;
}

int execute(Circuit *circuit, CircuitObject *object) {
    int oldOutput = object->outputState;
    int newOutput = object->outputState = calculate(object);
    
    if (newOutput == oldOutput) return newOutput;
    
    int c = 1;
    
    int i = 0;
    do {
        int o = oldOutput & c;
        int n = newOutput & c;
        if (o != n) {
            notifyCircuitConnectionWasUpdated(circuit, object->connections[object->numInputs + i]);
        }
        i++;
    } while (c<<=1);
    
    return newOutput;
}


void executeEventLoop(Circuit *circuit) {
    int i = 0;
    CircuitObject *object;
    while((object = eventLoop[i++])) {
        execute(circuit, object);
    }
    eventLoop[0] = NULL;
}

