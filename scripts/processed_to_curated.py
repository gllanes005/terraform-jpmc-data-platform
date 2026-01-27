"""
processed_to_curated.py
AWS Glue ETL job to create curated analytics-ready datasets

This script:
1. Reads processed data from the processed S3 bucket
2. Performs aggregations and business logic transformations
3. Creates analytics-ready datasets
4. Writes curated data to the curated S3 bucket optimized for querying
"""

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import (
    col, count, sum, avg, min, max,
    year, month, dayofmonth, current_timestamp
)
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get job parameters
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'SOURCE_BUCKET',
    'TARGET_BUCKET',
    'DATABASE_NAME'
])

# Initialize Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info(f"Starting job: {args['JOB_NAME']}")
logger.info(f"Source bucket: {args['SOURCE_BUCKET']}")
logger.info(f"Target bucket: {args['TARGET_BUCKET']}")

try:
    # Read processed data from S3
    source_path = f"s3://{args['SOURCE_BUCKET']}/data/"
    logger.info(f"Reading data from: {source_path}")
    
    # Read data as DynamicFrame
    processed_dynamic_frame = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={
            "paths": [source_path],
            "recurse": True
        },
        format="parquet",
        transformation_ctx="processed_dynamic_frame"
    )
    
    # Convert to Spark DataFrame
    df = processed_dynamic_frame.toDF()
    
    logger.info(f"Read {df.count()} records from processed data")
    
    # ====================================================================
    # Business Logic Transformations
    # ====================================================================
    
    # Example 1: Create aggregated summary table
    # Adjust based on your actual data structure
    
    # summary_df = df.groupBy("category").agg(
    #     count("*").alias("record_count"),
    #     sum("amount").alias("total_amount"),
    #     avg("amount").alias("avg_amount"),
    #     min("created_at").alias("first_seen"),
    #     max("created_at").alias("last_seen")
    # )
    
    # Example 2: Add analytical columns
    # df = df.withColumn("processing_timestamp", current_timestamp())
    # df = df.withColumn("year", year(col("created_at")))
    # df = df.withColumn("month", month(col("created_at")))
    # df = df.withColumn("day", dayofmonth(col("created_at")))
    
    # ====================================================================
    # Create Curated Datasets
    # ====================================================================
    
    # You can create multiple curated datasets for different use cases
    
    # Dataset 1: Main analytical dataset
    curated_df = df  # Apply your business logic transformations here
    
    logger.info(f"Curated dataset contains {curated_df.count()} records")
    
    # Convert to DynamicFrame
    curated_dynamic_frame = DynamicFrame.fromDF(
        curated_df,
        glueContext,
        "curated_dynamic_frame"
    )
    
    # ====================================================================
    # Write Curated Data
    # ====================================================================
    
    # Write to curated bucket optimized for analytics
    target_path = f"s3://{args['TARGET_BUCKET']}/analytics/"
    logger.info(f"Writing curated data to: {target_path}")
    
    glueContext.write_dynamic_frame.from_options(
        frame=curated_dynamic_frame,
        connection_type="s3",
        connection_options={
            "path": target_path,
            # Partition for optimal query performance
            # "partitionKeys": ["year", "month"]
        },
        format="parquet",
        transformation_ctx="write_curated",
        # Enable Snappy compression for better performance
        format_options={
            "compression": "snappy"
        }
    )
    
    # Optional: Write summary tables to separate locations
    # if 'summary_df' in locals():
    #     summary_dynamic_frame = DynamicFrame.fromDF(
    #         summary_df,
    #         glueContext,
    #         "summary_dynamic_frame"
    #     )
    #     
    #     summary_path = f"s3://{args['TARGET_BUCKET']}/summary/"
    #     glueContext.write_dynamic_frame.from_options(
    #         frame=summary_dynamic_frame,
    #         connection_type="s3",
    #         connection_options={"path": summary_path},
    #         format="parquet",
    #         transformation_ctx="write_summary"
    #     )
    
    logger.info("Job completed successfully")
    
except Exception as e:
    logger.error(f"Job failed with error: {str(e)}")
    raise

finally:
    job.commit()