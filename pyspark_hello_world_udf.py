import os

from pyspark.sql import SparkSession
from pyspark.sql.functions import udf, col
from pyspark.sql.types import StringType

@udf(returnType=StringType())
def say_hello(name: str) -> str:
    return f"Hello, {name}!"

print(os.getenv("JAVA_HOME"))

spark = SparkSession.builder.appName("UDF Example").getOrCreate()

data = [("Rick",), ("Morty",), ("Summer",)]
columns = ["name"]
df = spark.createDataFrame(data, columns)

print("Original DataFrame:")
df.show()

# def say_hello(name: str) -> str:
#     """A simple function to return a greeting."""
#     if name is None:
#         return None
#     return f"Hello, {name}!"

# You must specify the return type (StringType() in this case)
# say_hello_udf = udf(say_hello, StringType())

# The UDF is applied to the 'name' column, and the result is stored in a new 'greetings' column
df_greeted = df.withColumn("greetings", say_hello(col("name")))

print("DataFrame with UDF applied:")
df_greeted.show()

# 6. Stop the Spark session (optional, good practice)
spark.stop()
