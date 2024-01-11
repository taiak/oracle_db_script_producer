# ORACLE DATABASE SCRIPT PRODUCER
The 'ODSP' class produces the necessary scripts to create and move tables, sequences, indexes and constraints between the source and target databases for the Oracle database. By default, it produces with its own parameters. Additionally, problem-specific scripts can be produced by changing these parameters.

## Installation
To install this gem, the "ruby-oci8" gem must be installed. You can find detailed information at the [ installation link](https://github.com/kubo/ruby-oci8/tree/master/docs).

~~~ruby
gem install oracle_db_script_producer
~~~

## Usage Example


> #### **Source Environment**
> + *Username:* _**SRC_USER**_
> + *Password:* _**SRC_SUPER_SECRET_PASSWORD**_
> + *Hostname:* _**localhost**_
> + *Port:* _**1521**_
> + *Database Name:* _**free**_
> + *Connection* _**localhost:1521/free**_
> ##

> #### **Test Environment**
> + *Username:* _**TEST_USER**_
> + *Password:* _**EXTREME_WEAK_PASSWORD**_
> + *Hostname:* _**localhost**_
> + *Port:* _**1521**_
> + *Database Name:* _**free**_
> + *Connection* _**localhost:1521/free**_
> ##


~~~ruby
require 'odsp'

odsp = ODSP.new(
    save_config: {
        make: { folder: 'make', op_file: 'make_all.sql'},
        drop: { folder: 'drop', op_file: 'drop_all.sql'}
    },
    connections: {
        src:  OCI8.new('SRC_USER',  'SRC_SUPER_SECRET_PASSWORD', 'localhost:1521/free'),
        dest: OCI8.new('TEST_USER', 'EXTREME_WEAK_PASSWORD',     'localhost:1521/free')
    }
)

odsp.produce
~~~


After the code is run, two directories named 'make' and 'drop' are created in the running directory. 'create_table.sql', 'insert.sql', 'index.sql' and 'sequence.sql' files are created under the make directory. 'table.sql', 'index.sql' and 'sequence.sql' files are created under the drop directory.

In these scripts, the oracle script that will run the scripts under the make directory is written to the 'make_all.sql' file defined with the op_file parameter, and the scripts under the drop directory are written to the 'drop_all.sql' file.


~~~ruby
require 'odsp'

params = [
    {
        type:       'drop_index',
        connection: :dest,
        op_type:    :drop,
        lambda:     lambda { |arr| "DROP INDEX TEST_USER.#{arr[0]};\n" },
        query:      "SELECT object_name FROM user_objects WHERE status = 'VALID' AND object_type = 'INDEX' ORDER BY CREATED, TIMESTAMP\n"
    },
    {
        type:       'drop_table',
        connection: :dest,
        op_type:    :drop,
        lambda:     lambda { |arr| "DROP TABLE TEST_USER.#{arr[0]};\n" },
        query:      "SELECT object_name FROM user_objects WHERE status = 'VALID' AND object_type = 'TABLE' ORDER BY CREATED, TIMESTAMP\n"
    }
]

odsp = ODSP.new(
    save_config: { drop: { folder: 'drop', op_file: 'drop_all.sql'} },
    connections: { 
        dest: OCI8.new('TEST_USER', 'EXTREME_WEAK_PASSWORD',     'localhost:1521/free')
    },
    params: params
)

odsp.produce

~~~

After the code is run, a directories named 'drop' are created in the running directory. **drop_index.sql** and **drop_table.sql** files are created under the drop directory. And 

In these scripts, the oracle script that will run the scripts under the drop directory is written to the **drop_all.sql** file defined with the op_file parameter.

## **params** Parameter Syntax

The **params** parameter is a hash array containing the commands to be executed.The params parameter is a hash string containing the commands to be executed. Type, connection, op_type, lambda and query parameters must be defined for each element.

Each command under prams is executed in the order given in params. It is added into operation files such as make_all.sql in this order. While each command is executed, the given **query** query is executed with the **connection** connection. Each incoming line is processed according to the function given in **lambda**. Each processed line is written to a file as **type**.sql under the file corresponding to the symbol given under **op_type** in **save_config**.

> ### These parameters:
> * **type:** is a specifier that holds the file name to be written to.
> * **connection:** the query to be given
> * **op_type:** which file will be written under save_config after processing and under which op_file it will be located
> * **lambda:** function that specifies how the results from the query will be processed
> * **query:** SQL query about which values to process
> ##

##  Advanced Lambda Settings

For the use of advanced lambda functions, we can generate a part of the string based on connection or another string, while making the remaining part run after the query runs.

For the use of advanced lambda functions, we can generate a part of the string based on connection or another string, while making the remaining part run after the query runs.

In the example below, instead of being defined statically as **TEST_USER**, the username can be defined dynamically as **connections[:dest].username**.

In addition, the parameters received in the query can be processed by using the variable of the yield parameter you give for parameter use in lambda functions as an array object.

~~~ruby

# In this example, only one parameter (index name) is given. 
# And this parameter can be accessed by using arr[0].
l1 = lambda { |arr| "DROP INDEX TEST_USER.#{arr[0]};\n" }

# In this example, it can be seen that there are 8 parameters. 
# And these parameters can be accessed through the arr array from 0 to 8.
l2 = lambda { |arr| "CREATE SEQUENCE TEST_USER.#{arr[0]} MINVALUE #{arr[1]} MAXVALUE #{arr[2]} START WITH #{arr[3]} INCREMENT BY #{arr[4]} #{arr[5]} #{arr[6]} #{arr[7]};\n" }

~~~

Example external params usage example is as follows.  

~~~ruby
require 'odsp'

connections = { 
    dest: OCI8.new('TEST_USER', 'EXTREME_WEAK_PASSWORD',     'localhost:1521/free')
}

params = [
    {
        type:       'drop_index',
        connection: :dest,
        op_type:    :drop,
        lambda:     lambda { |arr| "DROP INDEX #{connections[:dest].username}.#{arr[0]};\n" },
        query:      "SELECT object_name FROM user_objects WHERE status = 'VALID' AND object_type = 'INDEX' ORDER BY CREATED, TIMESTAMP\n"
    },
    {
        type:       'drop_table',
        connection: :dest,
        op_type:    :drop,
        lambda:     lambda { |arr| "DROP TABLE TEST_USER.#{arr[0]};\n" },
        query:      "SELECT object_name FROM user_objects WHERE status = 'VALID' AND object_type = 'TABLE' ORDER BY CREATED, TIMESTAMP\n"
    }
]

odsp = ODSP.new(
    save_config: { drop: { folder: 'drop', op_file: 'drop_all.sql'} },
    connections: connections,
    params: params
)

odsp.produce

~~~

Another usage example is as follows.

~~~ruby

require 'odsp'

connections =     connections: {
    src:  OCI8.new('SRC_USER',  'SRC_SUPER_SECRET_PASSWORD', 'localhost:1521/free'),
    dest: OCI8.new('TEST_USER', 'EXTREME_WEAK_PASSWORD',     'localhost:1521/free')
}

params = [
    {
        type:       'constraint',
        connection: :src,
        op_type:    :drop,
        lambda:     lambda { |arr| "ALTER TABLE #{connections[:dest].username}.#{arr[0]} DROP CONSTRAINT #{arr[1]};\n" },
        query:      "SELECT DISTINCT TABLE_NAME, CONSTRAINT_NAME FROM (\n" +
                    "   SELECT TABLE_NAME, CONSTRAINT_NAME FROM USER_CONSTRAINTS  WHERE OWNER = '#{connections[:dest].username}'\n" +
                    "       UNION ALL\n" +
                    "   SELECT TABLE_NAME, CONSTRAINT_NAME FROM ALL_CONSTRAINTS   WHERE OWNER = '#{connections[:dest].username}'\n" +
                    "       UNION ALL \n" +
                    "   SELECT TABLE_NAME, CONSTRAINT_NAME FROM ALL_CONS_COLUMNS  WHERE OWNER = '#{connections[:dest].username}'\n" +
                    "       UNION ALL \n" +
                    "   SELECT TABLE_NAME, CONSTRAINT_NAME FROM USER_CONS_COLUMNS WHERE OWNER = '#{connections[:dest].username}'\n" +
                    ")\n"
    },
    {
        type:       'index',
        connection: :src,
        op_type:    :drop,
        lambda:     lambda { |arr| "DROP INDEX #{connections[:dest].username}.#{arr[0]};\n" },
        query:      "SELECT index_name FROM ALL_INDEXES WHERE TABLE_OWNER = '#{connections[:dest].username}'\n"
    },
    {
        type:       'sequence',
        connection: :src,
        op_type:    :drop,
        lambda:     lambda { |arr| "DROP SEQUENCE #{connections[:dest].username}.#{arr[0]};\n" },
        query:      "SELECT SEQUENCE_NAME FROM USER_SEQUENCES\n"
    },
    {
        type:       'table',
        connection: :src,
        op_type:    :drop,
        lambda:     lambda { |arr| "DROP TABLE #{connections[:dest].username}.#{arr[0]};\n" },
        query:      "SELECT DISTINCT TABLE_NAME FROM(\n" +
                    "    SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = '#{connections[:dest].username}'\n" +
                    "    UNION ALL\n" +
                    "    SELECT TABLE_NAME FROM USER_TABLES\n" +
                    ")\n"
    },
    {
        type:       'constraint',
        connection: :dest,
        op_type:    :make,
        lambda:     lambda { |arr| "CREATE SEQUENCE #{connections[:dest].username}.#{arr[0]} MINVALUE #{arr[1]} MAXVALUE #{arr[2]} START WITH #{arr[3]} INCREMENT BY #{arr[4]} #{arr[5]} #{arr[6]} #{arr[7]};\n"},
        query:      "SELECT DISTINCT CONSTRAINT_NAME FROM (\n" +
                    "	SELECT CONSTRAINT_NAME FROM USER_CONSTRAINTS\n" +
                    "	UNION ALL\n" +
                    "  SELECT CONSTRAINT_NAME FROM ALL_CONSTRAINTS WHERE OWNER = '#{connections[:src].username}'\n" +
                    ")\n"
    },
    {
        type:       'index',
        connection: :dest,
        op_type:    :make,
        lambda:     lambda { |arr| "CREATE #{arr[0]} INDEX #{arr[1]} ON '#{connections[:dest].username}'.#{arr[2]}(#{arr[3]});\n" },
        query:      "SELECT IS_UNIQUE, INDEX_NAME, TABLE_NAME, COLUMN_NAME\n" +
                    "FROM (\n" +
                    "  SELECT CASE\n" +
                    "    WHEN UNIQUENESS <> 'UNIQUE' THEN ' '\n" +
                    "    ELSE UNIQUENESS\n" +
                    "    END AS IS_UNIQUE,\n" +
                    "    A.INDEX_NAME AS INDEX_NAME,\n" +
                    "    A.TABLE_NAME AS TABLE_NAME,\n" +
                    "    A.COLUMN_NAME AS COLUMN_NAME\n" +
                    "  FROM ALL_IND_COLUMNS A, USER_INDEXES U\n" +
                    "  WHERE A.INDEX_OWNER = '#{connections[:src].username}'\n" +
                    "    AND U.INDEX_NAME  = A.INDEX_NAME\n" +
                    "    AND A.INDEX_NAME NOT LIKE 'SYS%'\n" +
                    "    AND A.INDEX_NAME NOT LIKE 'BIN%'\n" +
                    "    AND U.INDEX_NAME NOT LIKE 'SYS%'\n" +
                    ")\n"
    },
    #   In this example, instead of having Oracle generate the sequence ddl, 
    # it aims to create a sequence create query dynamically.
    {
        type:       'sequence',
        connection: :dest,
        op_type:    :make,
        lambda:     lambda { |arr| "CREATE SEQUENCE #{connections[:dest].username}.#{arr[0]} MINVALUE #{arr[1]} MAXVALUE #{arr[2]} START WITH #{arr[3]} INCREMENT BY #{arr[4]} #{arr[5]} #{arr[6]} #{arr[7]};\n" },
        query:      "SELECT SEQUENCE_NAME, \n" +
                    "  TO_CHAR(MIN_VALUE) MIN_VALUE,\n" +
                    "  TO_CHAR(MAX_VALUE) MAX_VALUE,\n" +
                    "  TO_CHAR(LAST_NUMBER + 1) LAST_NUMBER,\n" +
                    "  TO_CHAR(INCREMENT_BY) INCREMENT_BY, \n" +
                    "  CASE WHEN ORDER_FLAG = 'Y' THEN 'ORDER' ELSE 'NOORDER' END as ORDER_TYPE,\n" +
                    "  CASE WHEN CYCLE_FLAG = 'Y' THEN 'CYCLE' ELSE 'NOCYCLE' END as CYCLE_TYPE,\n" +
                    "  CASE WHEN CACHE_SIZE >  0  THEN 'CACHE ' || CACHE_SIZE ELSE 'NOCACHE' END as CACHE_TYPE\n" +
                    "FROM USER_SEQUENCES \n"
    },
    #
    #   In this example, since retrieving all the data in the 'EXAMPLE_CLOB_TABLE' table while copying the database may cause
    # too much weight for the test environment, the aim is to copy the data after a certain interval with an id-based 
    # limitation. Additionally, if a date is kept for the data, data within the last 3 months or 6 months can be retrieved via # SQL query.
    {
        type:       'table',
        connection: :dest,
        op_type:    :make,
        lambda:     lambda { |arr|
                    if arr[0] == 'EXAMPLE_CLOB_TABLE' 
                        "CREATE TABLE #{connections[:dest].username}.#{arr[0]} AS (SELECT * FROM #{connections[:src].username}.#{arr[0]} t WHERE t.id > 500 );\n"
                    else
                        "CREATE TABLE #{connections[:dest].username}.#{arr[0]} AS (SELECT * FROM #{connections[:src].username}.#{arr[0]});\n"
                    end
        },
        query:      "SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME NOT IN ('TOAD_PLAN_TABLE') AND TABLE_NAME NOT LIKE 'SYS_EXPORT_FULL_%'"
    }
]

odsp = ODSP.new(
    connections: connections,
    params: params
)

odsp.produce

~~~

## NOTICES

The Connections parameter must be defined in any case. The **save_config** parameter is given as below by default. Since it is a default parameter, giving it as a parameter is optional. 

~~~ruby
save_config = {
    make: { folder: 'make', op_file: 'make_all.sql'},
    drop: { folder: 'drop', op_file: 'drop_all.sql'}
}
~~~

The simplest usage is as given below.

~~~ruby
require 'odsp'

odsp = ODSP.new(
    connections: { 
        src:  OCI8.new('SRC_USER',  'SRC_SUPER_SECRET_PASSWORD', 'localhost:1521/free'),
        dest: OCI8.new('TEST_USER', 'EXTREME_WEAK_PASSWORD',     'localhost:1521/free')
    }
)

odsp.produce
~~~


## ADDITIONAL PARAMETERS

In addition to the params, connection and save_config parameters, there are also debug options abbreviated as **debug_opt**.

These options are called **time**, **console**, **commit**, **comment**.

>
> * **time:** Print the execution time of each script in seconds to the console? Default value is true.
> * **console:** Can a value be printed to the console? Default value is true.
> * **commit:** Should the "COMMIT" statement be added to the end of each script as a sql script? Default value is false.
> * **comment:** Should the scripts generation time be printed at the top of the scripts? Default value is true.

Example usage of **debug_opt** is as follows.

~~~ruby
require 'odsp'

odsp = ODSP.new(
    connections: { 
        src:  OCI8.new('SRC_USER',  'SRC_SUPER_SECRET_PASSWORD', 'localhost:1521/free'),
        dest: OCI8.new('TEST_USER', 'EXTREME_WEAK_PASSWORD',     'localhost:1521/free')
    },
    debug_opt: { time: true, console: true, commit: false, comment: true }
)

odsp.produce
~~~