#install.packages(c("RSelenium","wdman","binman"))
#install.packages("netstat")
#install.packages("purrr")
library(RSelenium)
library(netstat)
library(purrr)

# Cleanup existing processes
system("taskkill /im java.exe /f /t", show.output.on.console = FALSE)
system("taskkill /im geckodriver.exe /f /t", show.output.on.console = FALSE)

tryCatch({
  # Initialize Selenium
  port_number <- free_port()
  remote_Driver <- rsDriver(
    browser = "firefox",
    chromever = NULL,
    port = port_number,
    verbose = FALSE,
    check = FALSE
  )
  remDr <- remote_Driver$client
  
  # Navigate to target page
  remDr$navigate("https://www.glassdoor.de/Job/data-analyst-jobs-SRCH_KO0,12.htm")
  Sys.sleep(3)
  
  # Initialize control variables
  popup_closed <- FALSE
  page_counter <- 1
  
  # Continuous loading loop with safe handling
  while(TRUE) {
    # Check for load more button with error handling
    load_more <- tryCatch({
      remDr$findElement("css", "button[data-test='load-more']")
    }, error = function(e) NULL)
    
    # Exit condition when button not found
    if(is.null(load_more)) {
      message("\nReached end of job listings")
      break
    }
    
    # Click load more button
    try({
      remDr$executeScript("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", list(load_more))
      remDr$executeScript("arguments[0].click();", list(load_more))
      page_counter <- page_counter + 1
      message("Loaded page ", page_counter)
    }, silent = TRUE)
    
    # Handle popup once after first load
    if (!popup_closed && page_counter == 2) {
      try({
        Sys.sleep(1.5)
        close_btn <- remDr$findElement("css", "button.CloseButton")
        remDr$executeScript("arguments[0].click();", list(close_btn))
        popup_closed <- TRUE
        message("Popup closed successfully")
      }, silent = TRUE)
    }
    
    # Randomized delay with content wait
    Sys.sleep(runif(1, 3, 5))
  }
  
  # Final content stabilization
  Sys.sleep(3)
  remDr$executeScript("window.scrollTo(0, document.body.scrollHeight)")
  Sys.sleep(1)
  
  # Extraction function with error handling
  extract_text <- function(css) {
    remDr$findElements("css", css) %>% 
      map_chr(~try(.x$getElementText()[[1]], silent = TRUE)) %>% 
      discard(is.null)
  }
  
  # Get all job data
  titles <- extract_text("a[data-test='job-title']")
  employers <- extract_text("span.EmployerProfile_compactEmployerName__9MGcV")
  locations <- extract_text("div.JobCard_location__Ds1fM")
  skills <- extract_text("div.JobCard_jobDescriptionSnippet__l1tnl div:nth-of-type(2)") %>% 
    gsub("Kenntnisse und Fähigkeiten: ", "", .)
  ratings <- extract_text("span.rating-single-star_RatingText__XENmU") %>% 
    gsub(",", ".", .) %>% as.numeric()
  
  # Create aligned data frame
  max_len <- max(length(titles), length(employers), length(locations), length(skills), length(ratings))
  job_data <- data.frame(
    Title = c(titles, rep(NA, max_len - length(titles))),
    Employer = c(employers, rep(NA, max_len - length(employers))),
    Location = c(locations, rep(NA, max_len - length(locations))),
    Skills = c(skills, rep(NA, max_len - length(skills))),
    Rating = c(ratings, rep(NA, max_len - length(ratings))),
    stringsAsFactors = FALSE
  )
  
  # Save results
  write.csv(job_data, "glassdoor_jobs.csv", row.names = FALSE)
  message("\nSuccessfully saved ", nrow(job_data), " jobs to glassdoor_jobs.csv")
  
}, error = function(e) {
  message("Script error: ", e$message)
}, finally = {
  if(exists("remDr")) try(remDr$close(), silent = TRUE)
  if(exists("remote_Driver")) try(remote_Driver$server$stop(), silent = TRUE)
  message("Session closed")
})
