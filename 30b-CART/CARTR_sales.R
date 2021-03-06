# CART Models

library(rpart)
library(rpart.plot)
library(forecast)
#install.packages("https://cran.r-project.org/bin/windows/contrib/3.3/RGtk2_2.20.31.zip", repos=NULL)
#library(RGtk2)
#install.packages("rattle")
#library(rattle)


# Set the working directory to folder where you have placed the Input Data


MerSales2 = read.csv(file = "./data/msales.csv", skip=1, header = T)
MerSales= MerSales2
dim(MerSales)
# Summarize the dataset
summary(MerSales)
str(MerSales)
# Look at the average Annual_Sales()
for(i in 2:ncol(MerSales))
{
  if(length(unique(MerSales[,i])) <= 5)
  {
    AnnualSales = aggregate(x =  MerSales$sales, by = list(MerSales[,i]), FUN = mean)
    print(colnames(MerSales)[i])
    print(AnnualSales)
    print("*******************************************")
  }
}

aggregate(MerSales$sales, by=list(MerSales$loc), FUN=sum)
# Make a copy of the Original Dataset
MerSalesUncapped = MerSales

# Random Sampling
set.seed(777) # To ensure reproducibility
Index = sample(x = 1:nrow(MerSalesUncapped), size = 0.7*nrow(MerSalesUncapped))
Index
length(Index)
# Create Train dataset
MerSalesTrainUncapped = MerSalesUncapped[Index, ]
nrow(MerSalesTrainUncapped)
summary(object = MerSalesTrainUncapped)

# Create Test dataset
MerSalesTestUncapped = MerSalesUncapped[-Index, ]
nrow(MerSalesTestUncapped)
summary(object = MerSalesTestUncapped)
#divide data into 2 parts - Train (70%), Test(30%)

########################### Modeling ############################

# Build a full model with default settings
set.seed(123) # To ensure reproducibility of xerrors (cross validated errors while estimating complexity paramter for tree pruning)

CartFullModel = rpart(sales ~ . , data = MerSalesTrainUncapped[,-1], method = "anova")
CartFullModel
summary(object = CartFullModel)


# Plot the Regression Tree
rpart.plot(CartFullModel, type = 4,fallen.leaves = T,nn=T, cex = 1)

mean(MerSalesTrainUncapped$sales)

title("CartFullModel") # Enlarge the plot by clicking on Zoom button in Plots Tab on R Studio

# fancyRpartPlot() function to plot the same model
# Expand the plot window in R Studio to see a presentable output
fancyRpartPlot(model = CartFullModel, main = "CartFullModel", cex = 0.6) 
?fancyRpartPlot
# The following code also produces the same output, but in a windowed form
windows()
fancyRpartPlot(model = CartFullModel, main = "CartFullModel", cex = 0.6)


# The CP table also shows us valueable information in terms of pruning the tree (which is explained later in the code)
 # => The complexity parameter "CP" specifies how the cost of a tree C(T) is penalized by the number of terminal nodes |T|.
 # Hence, Small "CP" results in larger trees and potential overfitting, large CP" in small trees and potential underfitting.
 # => The "rel error" is 1- RSquare, similar to linear regression. This is the error on the observations used to estimate the model. The last node value of rel error suggests the R-Square of the model, if this happens to be the model
 # => The "xerror" is is the error on the observations from cross validation data, which happens to be a 10-Fold Cross Validation. Particpants need to note that, in order to reproduce the "xerror" values, they must use the same set.seed() number each time
 # => Root Node Error is given by sum((Dependent - Mean(Dependent))^2), i.e.
 # sum((InsDataTrainUncapped$Losses-mean(InsDataTrainUncapped$Losses))^2
 
printcp(CartFullModel)

# This produces a plot which may help particpants to look for a model depending on R-Square values produced at various splits
rsq.rpart(x = CartFullModel)

fit4 = prune(CartFullModel, cp=.014)
fit4
rpart.plot(fit4, nn=T, cex=1)

########################### Using CP to expand / Prune the tree #################################################
# Lets change rpart.control() to specify certain attributes for tree building
RpartControl = rpart.control(cp = 0.005)
set.seed(123)
names(MerSales)
CartModel_1 = rpart(formula = sales ~ . , 
                    data = MerSalesTrainUncapped[,-1], 
                    method = "anova", control = RpartControl)

CartModel_1

CartModel_1$where
trainingnodes = rownames(CartModel_1$frame) [ CartModel_1$where]
trainingnodes

summary(CartModel_1)
rpart.plot(x = CartModel_1, type = 4,cex = 0.6)
printcp(x = CartModel_1)
rsq.rpart(x = CartModel_1)




####################### Some Extra pointers in R ###########################################


# Model Evaluation Measures on test dataset using the finalized (pruned model)
# Use predict() the get the predicted values for the testset using the finalized model

# Intermediate Model: Finalize CartFullModel (Based on Tree size i.e. Depth, Variables included as well as the R-Square produced)
# Predict on testset
CartFullModelPredictTest = predict(CartFullModel, newdata = MerSalesTestUncapped, type = "vector")
CartFullModelPredictTest[1]
MerSales[2,'sales']
# Calculate RMSE and MAPE manually
# Participants can calculate RMSE and MAPE using various available functions in R, but that may not
# communicate effectively the mathematical aspect behind the calculations

# RMSE
Act_vs_Pred = CartFullModelPredictTest - MerSalesTestUncapped$Annual_Sales # Differnce
Act_vs_Pred_Square = Act_vs_Pred^2 # Square
Act_vs_Pred_Square_Mean = mean(Act_vs_Pred_Square) # Mean
Act_vs_Pred_Square_Mean_SqRoot = sqrt(Act_vs_Pred_Square_Mean) # Square Root
Act_vs_Pred_Square_Mean_SqRoot

# MAPE
Act_vs_Pred_Abs = abs(CartFullModelPredictTest - MerSalesTestUncapped$sales) # Absolute Differnce
Act_vs_Pred_Abs_Percent = Act_vs_Pred_Abs/MerSalesTestUncapped$sales # Percent Error
Act_vs_Pred_Abs_Percent_Mean = mean(Act_vs_Pred_Abs_Percent)*100 # Mean
Act_vs_Pred_Abs_Percent_Mean
library(forecast)
# Validate RMSE and MAPE calculation with a function in R
UncappedModelAccuarcy = forecast::accuracy(f = CartFullModelPredictTest, x = MerSalesTestUncapped$sales)
UncappedModelAccuarcy



windows()
fancyRpartPlot(model = CartModel_1, main = "Final CART Regression Tree", cex = 0.6, sub = "Model 12")
