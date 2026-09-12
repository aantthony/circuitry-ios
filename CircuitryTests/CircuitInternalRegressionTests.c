#include "CircuitInternal.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void testFanout(void) {
    CircuitInternal *c = CircuitCreate();
    CircuitObject *source = CircuitObjectCreate(c, &CircuitProcessButton);
    CircuitObject *first = CircuitObjectCreate(c, &CircuitProcessLight);
    CircuitObject *second = CircuitObjectCreate(c, &CircuitProcessLight);
    CircuitSimulate(c, 10);
    CircuitObjectSetOutput(c, source, 1);
    // Wiring while an output change is queued can leave different inputs on
    // the same outlet until the next tick.
    CircuitLinkCreate(c, source, 0, first, 0);
    CircuitObjectSetOutput(c, source, 0);
    CircuitLinkCreate(c, source, 0, second, 0);
    CircuitObjectSetOutput(c, source, 1);
    CircuitSimulate(c, 10);
    assert(first->in == 1);
    assert(second->in == 1);
    CircuitDestroy(c);
}

static void testLinkGrowth(void) {
    CircuitInternal *c = CircuitCreate();
    free(c->links);
    c->links_size = 1;
    c->links = malloc(sizeof(CircuitLink));
    CircuitObject *source = CircuitObjectCreate(c, &CircuitProcessButton);
    CircuitObject *first = CircuitObjectCreate(c, &CircuitProcessLight);
    CircuitObject *second = CircuitObjectCreate(c, &CircuitProcessLight);
    CircuitLinkCreate(c, source, 0, first, 0);
    CircuitLinkCreate(c, source, 0, second, 0);
    assert(source->outputs[0] == first->inputs[0]);
    assert(source->outputs[0]->nextSibling == second->inputs[0]);
    CircuitObjectSetOutput(c, source, 1);
    CircuitSimulate(c, 10);
    assert(first->in == 1 && second->in == 1);
    CircuitLinkRemove(c, first->inputs[0]);
    CircuitLinkRemove(c, second->inputs[0]);
    CircuitDestroy(c);
}

static void testQueueGrowth(void) {
    CircuitInternal *c = CircuitCreate();
    CircuitObject *source = CircuitObjectCreate(c, &CircuitProcessButton);
    CircuitObject *targets[8];
    for (int i = 0; i < 8; i++) {
        targets[i] = CircuitObjectCreate(c, &CircuitProcessNot);
        CircuitLinkCreate(c, source, 0, targets[i], 0);
    }
    CircuitSimulate(c, 10);
    free(c->needsUpdate);
    free(c->needsUpdate2);
    c->needsUpdate_size = 1;
    c->needsUpdate = malloc(sizeof(CircuitObject *));
    c->needsUpdate2 = malloc(sizeof(CircuitObject *));
    for (int state = 1; state >= 0; state--) {
        CircuitObjectSetOutput(c, source, state);
        CircuitSimulate(c, 10);
        for (int i = 0; i < 8; i++) {
            assert(targets[i]->in == state);
            assert(targets[i]->out == !state);
        }
    }
    CircuitDestroy(c);
}

static void testDestroyAfterRemoval(void) {
    CircuitInternal *c = CircuitCreate();
    CircuitObject *source = CircuitObjectCreate(c, &CircuitProcessClock);
    CircuitObject *target = CircuitObjectCreate(c, &CircuitProcessNot);
    CircuitLinkCreate(c, source, 0, target, 0);
    CircuitObjectRemove(c, source);
    CircuitSimulate(c, 10);
    assert(c->clocks_count == 0);
    assert(target->inputs[0] == NULL);
    CircuitDestroy(c);
}

int main(int argc, char **argv) {
    if (argc == 1 || strcmp(argv[1], "fanout") == 0) testFanout();
    if (argc == 1 || strcmp(argv[1], "links") == 0) testLinkGrowth();
    if (argc == 1 || strcmp(argv[1], "queue") == 0) testQueueGrowth();
    if (argc == 1 || strcmp(argv[1], "destroy") == 0) testDestroyAfterRemoval();
    puts("Circuit simulation regression tests passed.");
    return 0;
}
