def fit(xTrainMultiDim,yTrain,api,validation,**kargs):
  import sklearn.linear_model, sklearn.neighbors, sklearn.tree, sklearn.svm, numpy
  import sklearn.neural_network
  import sklearn.preprocessing as preprocess, sklearn.model_selection
  import sklearn.isotonic
  scalar = preprocess.StandardScaler() # scale
  scalar.fit(xTrainMultiDim); 
  ## if requested validation
  if validation: xTrainMultiDim,xQa,yTrain,yQa = splitData(xTrainMultiDim,yTrain,validation) #xTrainMultiDim,xQa,yTrain,yQa = sklearn.model_selection.train_test_split(xTrainMultiDim,yTrain)
  else: xQa,yQa = False,False
  xTrainMultiDim = scalar.transform(xTrainMultiDim)
  if api == 'ann':
    mlp = sklearn.neural_network.MLPClassifier(random_state=1,**kargs);
  elif api == 'annR':
    mlp = sklearn.neural_network.MLPRegressor(random_state=1,**kargs)
  elif api == 'lin':
    mlp = sklearn.linear_model.LinearRegression(**kargs)
  elif api == 'tree':
    mlp = sklearn.tree.DecisionTreeClassifier(random_state=1,**kargs)
  elif api == 'neighbor':
    mlp = sklearn.neighbors.KNeighborsClassifier(**kargs)
  elif api == 'svm':
    mlp = sklearn.svm.SVC(**kargs)
  elif api == 'isotonic':
    mlp = sklearn.isotonic.IsotonicRegression(random_state=1,**kargs)
    xTrainMultiDim = numpy.reshape(xTrainMultiDim,-1)
  mlp.fit(xTrainMultiDim,yTrain)
  return mlp,scalar,(xQa,yQa)

def splitData(xData,yData,xDimsToUse):
  import sklearn.model_selection
  xTrain = xData[xDimsToUse].drop_duplicates().reset_index(drop=True)   #uniquify the the xData based on xDims
  xTrain,xQa = sklearn.model_selection.train_test_split(xTrain)  # run the model selection
  #Get all the points from the remaining dimensions mapping the uniquified xData selection for Train and test
  xTrain = xData.merge(xTrain,how='inner'); xQa = xData.merge(xQa,how='inner')
  yTrain = yData.reindex(xTrain.index);     yQa = yData.reindex(xQa.index) 
#  xTrain,xQa,yTrain,yQa = list(map(lambda ff: ff.reset_index(drop=True), [xTrain,xQa,yTrain,yQa]))
  return  xTrain,xQa,yTrain,yQa

