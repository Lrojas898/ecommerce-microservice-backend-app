package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.domain.Favourite;
import com.selimhorri.app.domain.id.FavouriteId;
import com.selimhorri.app.dto.FavouriteDto;
import com.selimhorri.app.exception.wrapper.FavouriteNotFoundException;
import com.selimhorri.app.helper.FavouriteMappingHelper;
import com.selimhorri.app.repository.FavouriteRepository;

/**
 * Unit tests for FavouriteServiceImpl
 * Tests favourite product management functionality
 * Part of favourite-service microservice
 */
@ExtendWith(MockitoExtension.class)
class FavouriteServiceImplTest {

    @Mock
    private FavouriteRepository favouriteRepository;

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private FavouriteServiceImpl favouriteService;

    private Favourite favourite;
    private FavouriteDto favouriteDto;
    private FavouriteId favouriteId;

    @BeforeEach
    void setUp() {
        LocalDateTime likeDate = LocalDateTime.of(2025, 1, 15, 10, 30);

        this.favouriteId = new FavouriteId(1, 1, likeDate);

        this.favourite = Favourite.builder()
                .userId(1)
                .productId(1)
                .likeDate(likeDate)
                .build();

        this.favouriteDto = FavouriteMappingHelper.map(this.favourite);
    }

    @Test
    void save_shouldReturnSavedFavourite() {
        // given
        when(this.favouriteRepository.save(any(Favourite.class)))
                .thenReturn(this.favourite);

        // when
        final FavouriteDto result = this.favouriteService.save(this.favouriteDto);

        // then
        assertNotNull(result);
        assertEquals(this.favouriteDto.getUserId(), result.getUserId());
        assertEquals(this.favouriteDto.getProductId(), result.getProductId());
        verify(this.favouriteRepository, times(1)).save(any(Favourite.class));
    }

    @Test
    void update_shouldReturnUpdatedFavourite() {
        // given
        LocalDateTime newLikeDate = LocalDateTime.of(2025, 1, 20, 14, 45);
        final FavouriteDto updatedDto = this.favouriteDto;
        updatedDto.setLikeDate(newLikeDate);

        final Favourite updatedFavourite = FavouriteMappingHelper.map(updatedDto);
        when(this.favouriteRepository.save(any(Favourite.class)))
                .thenReturn(updatedFavourite);

        // when
        final FavouriteDto result = this.favouriteService.update(updatedDto);

        // then
        assertNotNull(result);
        assertEquals(newLikeDate, result.getLikeDate());
        verify(this.favouriteRepository, times(1)).save(any(Favourite.class));
    }

    @Test
    void deleteById_shouldCallRepositoryDelete() {
        // given
        final FavouriteId favouriteId = new FavouriteId(1, 1, LocalDateTime.now());

        // when
        this.favouriteService.deleteById(favouriteId);

        // then
        verify(this.favouriteRepository, times(1)).deleteById(favouriteId);
    }

    @Test
    void findById_shouldThrowException_whenFavouriteNotFound() {
        // given
        when(this.favouriteRepository.findById(any(FavouriteId.class)))
                .thenReturn(Optional.empty());

        // when, then
        assertThrows(FavouriteNotFoundException.class,
                () -> this.favouriteService.findById(this.favouriteId));
        verify(this.favouriteRepository, times(1)).findById(any(FavouriteId.class));
    }

    @Test
    void save_shouldPersistFavouriteCorrectly() {
        // given
        Favourite newFavourite = Favourite.builder()
                .userId(2)
                .productId(5)
                .likeDate(LocalDateTime.of(2025, 1, 25, 16, 0))
                .build();

        when(this.favouriteRepository.save(any(Favourite.class)))
                .thenReturn(newFavourite);

        FavouriteDto newFavouriteDto = FavouriteMappingHelper.map(newFavourite);

        // when
        final FavouriteDto result = this.favouriteService.save(newFavouriteDto);

        // then
        assertNotNull(result);
        assertEquals(2, result.getUserId());
        assertEquals(5, result.getProductId());
        assertNotNull(result.getLikeDate());
        verify(this.favouriteRepository, times(1)).save(any(Favourite.class));
    }
}
