CC = mpic++
CFLAGS = -Wall -Wextra -O2
LDFLAGS = -lm

TARGET = Merge_Sort_MPI
SRCS = Merge_Sort_MPI.cpp
OBJS = $(SRCS:.cpp=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET) $(LDFLAGS)

.cpp.o:
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)
