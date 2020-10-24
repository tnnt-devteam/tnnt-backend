#!/usr/bin/python

import random
import copy
import math
import sys

def emptymatrix(matrix):
    for row in matrix:
        if sum(row) > 0:
            return False
    return True

def total_multiplier(inputrow, inputmults, z_mults):
    # assume all three of these are the same length (nconducts)
    prod = 1
    for x in range(len(inputrow)):
        if inputrow[x] == 0:
            continue
        # assume inputrow is just 0s and 1s, so no need to multiply with it
        prod *= (((inputmults[x] - 1) / z_mults[x]) + 1)

    return prod

def greedyalgo(constmatrix, constmults):
    matrix = copy.deepcopy(constmatrix)
    ngames = len(matrix)
    nconducts = len(matrix[0])

    out_matrix = []
    for i in range(ngames):
        out_matrix.append([0] * nconducts)

    z_mults = [1] * nconducts # zscore denominators
    while True:
        # find row that will produce the highest total multiplier
        products = [1] * ngames
        maxprod = 0
        chosen = -1
        for i in range(ngames):
            row = matrix[i]
            if sum(row) > 0:
                products[i] = total_multiplier(row, constmults, z_mults)
                if products[i] > maxprod:
                    maxprod = products[i]
                    chosen = i
            else:
                # print('row', i, 'is empty')
                pass

        # print('ye have chosen', chosen)
        if chosen == -1:
            # all zero rows
            break

        # store the zscore info in out_matrix and tick up the zscore
        # denominators
        for i in range(nconducts):
            if matrix[chosen][i] > 0:
                out_matrix[chosen][i] = z_mults[i]
                z_mults[i] = z_mults[i] + 1

        # zero the chosen row
        matrix[chosen] = [0 * nconducts]

    return out_matrix


# return TNNT score of a given matrix
def score_matrix(matrix, mults):
    # this matrix is the output from the algo, not the input. however mults is input
    sumu = 0
    for row in matrix:
        fakerow = [1 if r > 0 else 0 for r in row]
        score = 50 * total_multiplier(fakerow, mults, row) # row is z_mults
        sumu += score
    return sumu

def rec_step(in_matrix, out_matrix, constmults, startrow, startcol):
    # print("recursed with", out_matrix)
    # search through out_matrix to find a value that is 1 in constmatrix but 0 in out_matrix
    w = len(in_matrix[0])
    h = len(in_matrix)
    recursed = False
    stoplooping = False
    maxscore = 0
    maxsoln = None
    for col in range(w):
        if stoplooping:
            break
        for row in range(h):
            if col < startcol or (col == startcol and row < startrow):
                continue
            if in_matrix[row][col] > 0 and out_matrix[row][col] == 0:
                # print('recursing on row, col', row, col)
                # recursive case: try all possible unassigned values in the column,
                # recurse on each, then return the best result
                recursed = True

                col_tot = 0
                for row2 in range(h):
                    if in_matrix[row2][col] > 0:
                        col_tot += 1
                # print('there are', col_tot, 'things in this column')

                poss = set([i for i in range(1, col_tot + 1)])
                # print('poss 1', poss)
                for row2 in range(h):
                    if out_matrix[row2][col] in poss:
                        poss.remove(out_matrix[row2][col])
                # print('poss ibilities', poss)

                for p in poss:
                    # print('trying value', p, 'at', row, col)
                    out_matrix[row][col] = p
                    score, soln = rec_step(in_matrix, out_matrix, constmults, row, col)
                    # print(score, maxscore, soln)
                    if score > maxscore:
                        maxscore = score
                        maxsoln = soln
                # clean up after itself
                out_matrix[row][col] = 0
                stoplooping = True
                break


    if recursed:
        return (maxscore, maxsoln)
    else:
        # base case: out_matrix has fully assigned all values. score it and return it
        score = score_matrix(out_matrix, constmults)
        # print('end of recursion:', out_matrix, 'score:', score)
        return (score, copy.deepcopy(out_matrix))


def refalgo(constmatrix, constmults):
    empty_matrix = []
    for row in constmatrix:
        empty_matrix.append([0] * len(constmatrix[0]))

    score, soln = rec_step(constmatrix, empty_matrix, constmults, 0, 0)
    return soln

G = [[0,0,1,1],
     [1,1,0,0],
     [1,0,0,1],
     [1,0,1,0]]
C = [2.8, 2.8, 1.9, 1.75]
# G = [[1,1],
#      [1,0]]
# C = [1.6, 1.1]

# res = greedyalgo(G, C)
# res = refalgo(G, C)
# print(res)
# print(score_matrix(res, C))

# sys.exit(0)

for i in range(10000):
    for row in range(len(G)):
        for col in range(len(G[0])):
            G[row][col] = random.randint(0,1)

    C = [random.uniform(1.0,3.0) for i in range(4)]

    gres = greedyalgo(G,C)
    refres = refalgo(G,C)
    scoreg = score_matrix(gres, C)
    scorer = score_matrix(refres, C)

    if not math.isclose(scoreg, scorer, rel_tol=0.1):
        print("INACCURACY")
        print("greedy:", gres, "score:", scoreg)
        print("reference:", refres, "score:", scorer)
        print("G:", G)
        print("C:", C)
        break
