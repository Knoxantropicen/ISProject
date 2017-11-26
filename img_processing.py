from PIL import Image
import numpy as np
from bitarray import *
import os

# parameters
IMAGE_NAME = 'test16.bmp'
MAX_ROUND = 2   # max round number (currently support 1, 2)
RANDOM_SEED = 0
SCHEME = 'BX'   # choose BX or MA

def main():
    np.random.seed(RANDOM_SEED)
    K = randomKeyGenerator()
    print('Key:', K)
    enc = Enc(IMAGE_NAME, K, MAX_ROUND, SCHEME)
    enc.encryption()
    enc.decryption()
    enc.saveResultImage()

def randomKeyGenerator():
    K = bitarray(256)
    K.setall(0)
    idx = np.random.choice(256, 128)
    for i in idx:
        K[i] = 1
    return K

# single random number generator
def LSS_PRNG(x, r):
    x_ = r * x * (1 - x) + (4 - r) * np.sin(np.pi * x) / 4
    x_ = np.mod(x_, 1)
    return x_

# random number sequence generator
def LSS_PRNG_sequence(x, r, length):
    sequence = []
    for _ in range(length):
        x = LSS_PRNG(x, r)
        sequence.append(x)
    return sequence

# convert bit array to float number (>= 0 and < 1)
def bitsToFloat(Bin):
    return np.sum(np.multiply(Bin, [2 ** -i for i in range(1, len(Bin)+1)]))

# convert bit array to int number (= 0 or >= 1)
def bitsToInt(Bin):
    return np.sum(np.multiply(Bin, [2 ** i for i in range(len(Bin))]))


# main class
class Enc:
    def __init__(self, imgname, K, max_round, scheme):
        # load image from file
        self.img = Image.open('test_image/' + imgname)
        rows, cols = self.img.size[0], self.img.size[1]
        img_array = np.asarray(self.img, dtype='int32')
        assert len(img_array.shape) >= 2    # image validation
        self.channel_3_dim = 1 if len(img_array.shape) == 2 else img_array.shape[2] # find 3rd channel dimension
        self.P = img_array.reshape(rows, cols, self.channel_3_dim)
        self.max_round = max_round      # max round number
        assert scheme == 'BX' or scheme == 'MA'
        self.scheme = scheme

        # initial states generation given K
        assert len(K) == 256
        self.K = K
        X0 = bitsToFloat(self.K[0:52])
        r  = bitsToFloat(self.K[52:104])
        d1 = bitsToInt(self.K[104:128])
        d2 = bitsToInt(self.K[128:152])
        R1 = bitsToFloat(self.K[152:204])
        R2 = bitsToFloat(self.K[204:256])
        self.X0 = [(d1 * (X0 + R1)) % 1, (d2 * (X0 + R2)) % 1]
        self.r  = [(d1 * (r + R1)) % 4, (d2 * (r + R2)) % 4]

        # store intermediate values
        self.Q_group = []
        self.T_group = []
        self.S_group = []

    def randomDataInsertion(self):
        R_shape = (1, self.P.shape[1], self.P.shape[2])
        O_shape = (self.P.shape[0] + 2, 1, self.P.shape[2])
        R = np.random.randint(0, 256, size=R_shape)
        O = np.random.randint(0, 256, size=O_shape)
        self.P = np.concatenate((R, self.P, R), axis=0)
        self.P = np.concatenate((O, self.P, O), axis=1)     # image with random padding
        self.M, self.N = self.P.shape[0], self.P.shape[1]   # image dimension

    def highSpeedScrambling(self, round):
        M, N = self.M, self.N

        # S matrix generation
        R = LSS_PRNG_sequence(self.X0[round], self.r[round], M + N)
        A, B = R[:M], R[M:]
        I, J = np.argsort(A), np.argsort(B)
        S = np.vstack([J] * M)
        for row in range(M):
            S[row] = np.roll(S[row], -I[row])
        self.S_group.append(S)

        # T matrix generation
        T = np.empty_like(self.P)
        for j in range(N):
            for i in range(M):
                r, c = i, S[i, j]
                m = (r - S[0, j]) % M
                n = S[m, j]
                T[m, n] = self.P[r, c]
        self.T_group.append(T)

    def pixelAdaptiveDiffusion(self, round):
        M, N = self.M, self.N
        T = self.T_group[round]

        # Q matrix generation
        Q_sequence = LSS_PRNG_sequence(self.X0[round], self.r[round], M * N * self.channel_3_dim)
        Q = (np.reshape(Q_sequence, (M, N, self.channel_3_dim)) * 256).astype(int)
        self.Q_group.append(Q)

        # C matrix generation
        self.C = np.empty_like(Q)
        if self.scheme == 'BX':
            self.C[0, 0] = T[0, 0] ^ T[M - 1, N - 1] ^ Q[0, 0]
            for j in range(1, N):
                self.C[0, j] = T[0, j] ^ self.C[0, j - 1] ^ Q[0, j]
            for i in range(1, M):
                for j in range(N):
                    self.C[i, j] = T[i, j] ^ self.C[i - 1, j] ^ Q[i, j]
        else:
            pass

        # prepare input for next round
        if round != self.max_round - 1:
            self.P = self.C

    def encryption(self):
        self.randomDataInsertion()
        round = 0
        # multiple-round encryption
        while round < self.max_round:
            print('Encryption round %d' % (round + 1))
            self.highSpeedScrambling(round)
            self.pixelAdaptiveDiffusion(round)
            round += 1
        else:
            self.img_encrypted = self.C     # save final encrypted image

    def decryption(self):
        M, N = self.M, self.N
        round = self.max_round - 1
        # multiple-round decryption
        while round + 1:
            print('Decryption round %d' % (self.max_round - round))
            Q = self.Q_group[round]
            T = self.T_group[round]
            S = self.S_group[round]

            # T matrix decryption
            if self.scheme == 'BX':
                T[0, 0] = self.C[0, 0] ^ T[M - 1, N - 1] ^ Q[0, 0]
                for j in range(1, N):
                    T[0, j] = self.C[0, j] ^ self.C[0, j - 1] ^ Q[0, j]
                for i in range(1, M):
                    for j in range(N):
                        T[i, j] = self.C[i, j] ^ self.C[i - 1, j] ^ Q[i, j]
            else:
                pass

            # P matrix decryption
            for j in range(N):
                for i in range(M):
                    m, n = i, S[i, j]
                    r = ((m - S[0, j]) % M)
                    c = S[r, j]
                    self.P[m, n] = T[r, c]

            if round != 0:
                # prepare input for next round
                self.C = self.P
            else:
                # remove inserted random data
                self.P = self.P[1:-1, 1:-1]
            round -= 1
        else:
            self.img_decrypted = self.P     # save final decypted image

    # general image saving interface
    def saveImage(self, image, type):
        img = Image.new(self.img.mode, (image.shape[0], image.shape[1]))
        img_data = image.reshape((-1, self.channel_3_dim))
        img.putdata(tuple(map(tuple, img_data)))
        img.save('output_image/' + type + '_' + IMAGE_NAME, format=self.img.format)

    # save necessary image results
    def saveResultImage(self):
        if not os.path.isdir('output_image'):
            os.mkdir('output_image')
        self.saveImage(self.img_encrypted, 'encrypted')
        self.saveImage(self.img_decrypted, 'decrypted')


if __name__ == '__main__':
    main()
