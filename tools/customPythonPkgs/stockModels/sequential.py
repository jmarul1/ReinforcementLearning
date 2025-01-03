import math, numpy as np
from sklearn.preprocessing import MinMaxScaler
from keras.models import Sequential
from keras.layers import Dense, LSTM


class sequence_model:
    def __init__(self, closeData, groups=14, farBack=60):
        ## Create a new dataframe with only the close column
        self.groups = 14
        self.farBack = math.ceil(farBack / groups)
        self.closeData = closeData
        ## Create groups and take the median from it
        groupsNum = math.floor(len(closeData) / self.groups)
        self.start = len(closeData) - groupsNum * self.groups
        self.closeSets = self._buildSets(closeData)
        self.scaler, self.scaleData = self._scaleData()
        self.xTrain, self.yTrain = self._trainData()

    def _buildSets(self, closeData):
        closeSets = []
        for ii in range(self.start, len(closeData), self.groups):
            closeSets.append([np.median(closeData[ii : ii + self.groups])])
        return closeSets

    def _scaleData(self):  # Scale the data
        scaler = MinMaxScaler(feature_range=[0, 1])
        return scaler, scaler.fit_transform(self.closeSets)

    def _trainData(self):
        xTrain = []
        yTrain = []
        for ii in range(self.farBack, len(self.scaleData)):
            xTrain.append(self.scaleData[ii - self.farBack : ii])
            yTrain.append(self.scaleData[ii])
        xTrain, yTrain = np.array(xTrain), np.array(yTrain)
        xTrain = np.reshape(xTrain, [xTrain.shape[0], xTrain.shape[1], 1])
        return xTrain, yTrain

    def trainme(self):  ## Build the LSTM model
        self.model = Sequential()
        self.model.add(
            LSTM(50, return_sequences=True, input_shape=(self.xTrain.shape[1], 1))
        )
        self.model.add(
            LSTM(50, return_sequences=False, input_shape=(self.xTrain.shape[1], 1))
        )
        self.model.add(Dense(25))
        self.model.add(Dense(1))
        ## Compile the model
        self.model.compile(optimizer="adam", loss="mean_squared_error")
        ## Train the model
        self.model.fit(self.xTrain, self.yTrain, batch_size=1, epochs=1)

    def predict(self):  ## get the real vs predictions
        xTest = []
        yReal = self.closeSets[:]
        predictions = self.closeSets[: self.farBack]
        for ii in range(self.farBack, len(self.scaleData) + 1):
            xTest.append(self.scaleData[ii - self.farBack : ii])
        xTest = np.array(xTest)
        xTest = np.reshape(xTest, [xTest.shape[0], xTest.shape[1], 1])
        preds = self.model.predict(xTest)
        self.predictions = np.append(predictions, self.scaler.inverse_transform(preds))
        rmse = np.sqrt(np.mean(self.predictions[:-1] - yReal) ** 2)  # Get the RMSE
