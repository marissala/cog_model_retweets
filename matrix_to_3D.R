pacman::p_load(tidyverse, utils)

data_pipeline <- function(path) {
  #' Expect file path of csv with columns: document, topic, user1, user2, ..., usern
  df <- read_csv(path)
  
  # Reads amount of time steps (assumes they're all the same amount) by reading document 1's length
  ntimesteps <- df %>% 
    filter(document==1) %>% 
    nrow
  
  # Inputs the tibble into our 3D-fier
  df %>%  
    long_to_3D(ntimesteps) %>%
    return
}

long_to_3D <- function(tib, ntimesteps) {
  #' Expect tibble with columns: document, topic, user1, user2, ..., usern
  # Makes document and topic into factors (not strictly necessary)
  long <- tib %>% 
    mutate(
      document=as.factor(document),
      topic=as.factor(topic)
    )
  
  # Defining empty list for agent timesteps retweeting information
  timestepslist <- c()
  # Finding ndocuments and nagents using the tibble
  ndocuments <- length(levels(long$document))
  nagents <- length(colnames(long)) - 2
  # Creating a 3D matrix with our values
  X <- array(NaN, c(ntimesteps, nagents, ndocuments))
  for(z in 1:ndocuments) {
    current_doc <- long %>% filter(document==z)
    # For each document...
    for(y in 1:nagents) {
      # ...go through all timesteps for each agent and...
      timestepslist <- current_doc %>% select(c(paste0("user",y)))
      for(x in 1:ntimesteps) {
        # ...get usern column of current document and insert timestep of that column into our 3D format!
        X[x,y,z] <- timestepslist[x,] %>% as.numeric()
      }
    }
  }
  return(X)
}

test_3D <- function() {
  #' Creates a tibble with 2 timesteps (see documents column) and 2 users and runs them through the data pipeline
  TESTTIBBLE <- tibble(document=c(1,1,2,2,3,3), topic=c(1,1,1,1,3,3), user1=c(1,0,1,0,0,1),user2=c(0,1,0,1,0,0))
  long_to_3D(TESTTIBBLE, 2) %>% 
    return
}

start_time = Sys.time()
test_3D()
end_time <- Sys.time()
end_time-start_time

start_time = Sys.time()
dataframe = data_pipeline("test_results_RT_overand_5.csv")
end_time <- Sys.time()
end_time-start_time
beep(sound = 1)
